import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'user_session.dart';

class ApiService {
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_envBaseUrl.trim().isNotEmpty) {
      return _envBaseUrl.trim();
    }

    // Android emulator cannot access host localhost directly.
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }

  static Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/analyze-image'),
      );
      request.headers.addAll(UserSession.authHeaders);

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
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

  static Future<Map<String, dynamic>> analyzeText(String extractedText) async {
    final text = extractedText.trim();
    if (text.isEmpty) {
      throw Exception(
        'OCR produced empty text. Try retaking the photo with better lighting.',
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/analyze'),
            headers: UserSession.authHeaders,
            body: jsonEncode({'text': text}),
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
}
