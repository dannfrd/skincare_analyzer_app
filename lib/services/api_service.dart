import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../utils/network_helper.dart';
import 'user_session.dart';

/// API Service untuk komunikasi dengan backend
/// 
/// Backend menggunakan Multi-Dataset RAG untuk analisis:
/// 1. OCR text di-extract dan di-clean
/// 2. Ingredient di-match dengan database MySQL
/// 3. Context di-retrieve dari 3 dataset:
///    - Dataset 1: Deskripsi lengkap (1000+ ingredient)
///    - Dataset 2: Kategori & fungsi (500+ ingredient)
///    - Dataset 3: BPOM ingredient berbahaya
/// 4. Data dari 3 dataset di-merge menjadi context lengkap
/// 5. Gemini AI menganalisis dengan context grounding dari 3 sumber
/// 6. Expert system memberikan safety scoring
/// 
/// Semua proses Multi-Dataset RAG terjadi di backend, Flutter hanya perlu:
/// - Kirim image/text ke backend
/// - Terima hasil analisis yang sudah ter-context dari 3 dataset
class ApiService {
  // Use centralized configuration
  static String get baseUrl => AppConfig.baseUrl;

  /// Test koneksi ke backend
  static Future<bool> testConnection() async {
    final result = await NetworkHelper.testBackendConnection(baseUrl);
    return result['success'] as bool;
  }

  /// Print diagnostics untuk debugging
  static Future<void> printDiagnostics() async {
    await NetworkHelper.printNetworkDiagnostics(baseUrl);
  }

  /// Analyze image menggunakan OCR + Multi-Dataset RAG + AI
  /// 
  /// Backend akan:
  /// 1. Extract text dari image (OCR)
  /// 2. Clean dan tokenize ingredient
  /// 3. Match dengan database MySQL
  /// 4. Retrieve context dari 3 dataset:
  ///    - Deskripsi lengkap ingredient
  ///    - Kategori dan fungsi ingredient
  ///    - BPOM data ingredient berbahaya
  /// 5. Merge data dari 3 sumber
  /// 6. Analyze dengan Gemini AI (context-grounded dari 3 dataset)
  /// 7. Return hasil analisis lengkap dengan warning BPOM jika ada
  static Future<Map<String, dynamic>> analyzeImage(
    File imageFile, {
    String? productName,
    String? productBrand,
    String? productCategory,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/analyze-image'),
      );

      final token = UserSession.token;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final name = productName?.trim();
      final brand = productBrand?.trim();
      final category = productCategory?.trim();

      if (name != null && name.isNotEmpty) {
        request.fields['product_name'] = name;
      }
      if (brand != null && brand.isNotEmpty) {
        request.fields['product_brand'] = brand;
      }
      if (category != null && category.isNotEmpty) {
        request.fields['product_category'] = category;
      }

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 180),
      );
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to analyze image: ${response.statusCode} - ${response.body}',
        );
      }
    } on SocketException catch (e) {
      throw Exception(
        'Cannot reach backend at $baseUrl. Make sure backend is running and, for real devices, use your LAN IP via --dart-define=API_BASE_URL=http://192.168.x.x:8000. Detail: $e',
      );
    } on HttpException catch (e) {
      throw Exception('HTTP error while connecting to backend: $e');
    } on FormatException catch (e) {
      throw Exception('Backend returned invalid JSON: $e');
    } catch (e) {
      throw Exception('Error connecting to backend: $e');
    }
  }

  /// Analyze text ingredient menggunakan Multi-Dataset RAG + AI
  /// 
  /// Backend akan:
  /// 1. Clean dan tokenize ingredient text
  /// 2. Match dengan database MySQL
  /// 3. Retrieve context dari 3 dataset (Multi-Dataset RAG):
  ///    - Dataset 1: Deskripsi lengkap (1000+ ingredient)
  ///    - Dataset 2: Kategori & fungsi (500+ ingredient)
  ///    - Dataset 3: BPOM ingredient berbahaya
  /// 4. Merge data dari 3 sumber untuk context lengkap
  /// 5. Build prompt dengan context untuk Gemini AI
  /// 6. Analyze dengan AI yang ter-ground pada 3 dataset
  /// 7. Expert system scoring
  /// 8. Return hasil analisis dengan warning BPOM jika ada
  static Future<Map<String, dynamic>> analyzeText(
    String extractedText, {
    String? productName,
    String? productBrand,
    String? productCategory,
  }) async {
    final text = extractedText.trim();
    if (text.isEmpty) {
      throw Exception(
        'OCR produced empty text. Try retaking the photo with better lighting.',
      );
    }

    final payload = <String, dynamic>{'text': text};
    final name = productName?.trim();
    final brand = productBrand?.trim();
    final category = productCategory?.trim();

    if (name != null && name.isNotEmpty) {
      payload['product_name'] = name;
    }
    if (brand != null && brand.isNotEmpty) {
      payload['product_brand'] = brand;
    }
    if (category != null && category.isNotEmpty) {
      payload['product_category'] = category;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/analyze'),
            headers: UserSession.authHeaders,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      throw Exception(
        'Failed to analyze extracted text: ${response.statusCode} - ${response.body}',
      );
    } on SocketException catch (e) {
      throw Exception(
        'Cannot reach backend at $baseUrl. Make sure backend is running and, for real devices, use your LAN IP via --dart-define=API_BASE_URL=http://192.168.x.x:8000. Detail: $e',
      );
    } on HttpException catch (e) {
      throw Exception('HTTP error while connecting to backend: $e');
    } on FormatException catch (e) {
      throw Exception('Backend returned invalid JSON: $e');
    } catch (e) {
      throw Exception('Error sending OCR text to backend: $e');
    }
  }

  static Future<List<dynamic>> getHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/history'),
        headers: UserSession.authHeaders,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('items')) return data['items'] as List<dynamic>;
        if (data is Map && data.containsKey('data')) return data['data'] as List<dynamic>;
        return [];
      } else {
        throw Exception('Failed to fetch history: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching history: $e');
    }
  }

  static Future<bool> saveAnalysisHistory(int analysisId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/history/save'),
        headers: UserSession.authHeaders,
        body: jsonEncode({'analysis_id': analysisId}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getAnalysisDetail(int analysisId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analysis/$analysisId'),
        headers: UserSession.authHeaders,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch analysis detail: ${response.statusCode} - ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (!decoded.containsKey('analysis_id') && decoded['id'] != null) {
          decoded['analysis_id'] = decoded['id'];
        }
        return decoded;
      }

      if (decoded is Map) {
        final mapped = decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        if (!mapped.containsKey('analysis_id') && mapped['id'] != null) {
          mapped['analysis_id'] = mapped['id'];
        }
        return mapped;
      }

      throw Exception('Invalid analysis detail response format');
    } catch (e) {
      throw Exception('Error fetching analysis detail: $e');
    }
  }

  /// Upload profile picture to backend
  static Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/profile/upload'),
      );

      final token = UserSession.token;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to upload profile picture: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error uploading profile picture: $e');
    }
  }

  /// Update user profile details (name, email, profile_picture, password)
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? profilePicture,
    String? password,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null && name.isNotEmpty) payload['name'] = name;
    if (email != null && email.isNotEmpty) payload['email'] = email;
    if (profilePicture != null && profilePicture.isNotEmpty) {
      payload['profile_picture'] = profilePicture;
    }
    if (password != null && password.isNotEmpty) payload['password'] = password;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profile/update'),
        headers: UserSession.authHeaders,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to update profile: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  /// Fetch product recommendations from INCIDecoder dataset
  /// based on ingredient overlap with the scanned product.
  static Future<List<Map<String, dynamic>>> getRecommendations(
    List<String> ingredients, {
    int limit = 6,
    String? category,
  }) async {
    if (ingredients.isEmpty) return [];
    try {
      final queryParams = {
        'ingredients': ingredients.join(','),
        'limit': limit.toString(),
      };
      if (category != null && category.trim().isNotEmpty) {
        queryParams['category'] = category.trim();
      }
      final uri = Uri.parse('$baseUrl/recommendations').replace(
        queryParameters: queryParams,
      );
      final response = await http
          .get(uri, headers: UserSession.authHeaders)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final recs = data['recommendations'];
        if (recs is List) {
          return recs
              .whereType<Map>()
              .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
