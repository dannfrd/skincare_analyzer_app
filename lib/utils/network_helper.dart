import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Helper untuk test koneksi network dan backend
class NetworkHelper {
  /// Test apakah device punya koneksi internet
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Test apakah backend URL bisa diakses
  static Future<Map<String, dynamic>> testBackendConnection(String baseUrl) async {
    final result = {
      'success': false,
      'message': '',
      'url': baseUrl,
      'statusCode': 0,
      'responseTime': 0,
    };

    try {
      final stopwatch = Stopwatch()..start();
      
      // Try to ping backend health endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 10));
      
      stopwatch.stop();
      
      result['statusCode'] = response.statusCode;
      result['responseTime'] = stopwatch.elapsedMilliseconds;
      
      if (response.statusCode == 200) {
        result['success'] = true;
        result['message'] = 'Backend connected successfully (${stopwatch.elapsedMilliseconds}ms)';
      } else {
        result['message'] = 'Backend responded with status ${response.statusCode}';
      }
    } on SocketException catch (e) {
      result['message'] = 'Cannot reach backend: ${e.message}. Check if:\n'
          '1. Backend is running\n'
          '2. URL is correct\n'
          '3. Firewall allows connection\n'
          '4. Device has internet access';
    } on TimeoutException catch (_) {
      result['message'] = 'Connection timeout. Backend might be slow or unreachable.';
    } on HttpException catch (e) {
      result['message'] = 'HTTP error: ${e.message}';
    } catch (e) {
      result['message'] = 'Unexpected error: $e';
    }

    return result;
  }

  /// Test multiple URLs dan return yang paling cepat
  static Future<String?> findBestBackendUrl(List<String> urls) async {
    final results = await Future.wait(
      urls.map((url) => testBackendConnection(url)),
    );

    // Filter yang success
    final successResults = results.where((r) => r['success'] == true).toList();
    
    if (successResults.isEmpty) {
      return null;
    }

    // Sort by response time
    successResults.sort((a, b) => 
      (a['responseTime'] as int).compareTo(b['responseTime'] as int)
    );

    return successResults.first['url'] as String;
  }

  /// Get detailed network info untuk debugging
  static Future<Map<String, dynamic>> getNetworkInfo() async {
    final info = <String, dynamic>{};

    try {
      // Check internet
      info['hasInternet'] = await hasInternetConnection();

      // Get network interfaces
      final interfaces = await NetworkInterface.list();
      info['interfaces'] = interfaces.map((i) => {
        'name': i.name,
        'addresses': i.addresses.map((a) => {
          'address': a.address,
          'type': a.type.name,
          'isLoopback': a.isLoopback,
        }).toList(),
      }).toList();

      // Check IPv6 support
      info['hasIPv6'] = interfaces.any((i) => 
        i.addresses.any((a) => a.type == InternetAddressType.IPv6 && !a.isLoopback)
      );

    } catch (e) {
      info['error'] = e.toString();
    }

    return info;
  }

  /// Print network diagnostics
  static Future<void> printNetworkDiagnostics(String backendUrl) async {
    print('\n=== NETWORK DIAGNOSTICS ===');
    
    // Internet check
    final hasInternet = await hasInternetConnection();
    print('Internet: ${hasInternet ? "✓ Connected" : "✗ No connection"}');

    // Network info
    final networkInfo = await getNetworkInfo();
    print('IPv6 Support: ${networkInfo['hasIPv6'] ? "✓ Yes" : "✗ No"}');

    // Backend test
    print('\nTesting backend: $backendUrl');
    final backendTest = await testBackendConnection(backendUrl);
    print('Backend Status: ${backendTest['success'] ? "✓" : "✗"} ${backendTest['message']}');
    
    if (backendTest['statusCode'] != 0) {
      print('Status Code: ${backendTest['statusCode']}');
      print('Response Time: ${backendTest['responseTime']}ms');
    }

    print('===========================\n');
  }
}
