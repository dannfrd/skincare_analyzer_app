import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

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
            headers: {'Content-Type': 'application/json'},
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
}
