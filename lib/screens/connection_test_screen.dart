import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../utils/network_helper.dart';
import '../services/api_service.dart';

class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  bool _testing = false;
  Map<String, dynamic>? _testResult;
  Map<String, dynamic>? _networkInfo;
  String _customUrl = '';

  @override
  void initState() {
    super.initState();
    _customUrl = AppConfig.baseUrl;
    _runTest();
  }

  Future<void> _runTest() async {
    setState(() {
      _testing = true;
      _testResult = null;
      _networkInfo = null;
    });

    try {
      // Get network info
      final networkInfo = await NetworkHelper.getNetworkInfo();
      
      // Test backend connection
      final testResult = await NetworkHelper.testBackendConnection(_customUrl);

      setState(() {
        _networkInfo = networkInfo;
        _testResult = testResult;
        _testing = false;
      });
    } catch (e) {
      setState(() {
        _testResult = {
          'success': false,
          'message': 'Error: $e',
        };
        _testing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Test'),
        backgroundColor: const Color(0xFF68D377),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Configuration
            _buildSection(
              'Current Configuration',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Environment', AppConfig.environment),
                  _buildInfoRow('Backend URL', AppConfig.baseUrl),
                  _buildInfoRow('Platform', Theme.of(context).platform.name),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Custom URL Test
            _buildSection(
              'Test Custom URL',
              Column(
                children: [
                  TextField(
                    controller: TextEditingController(text: _customUrl),
                    decoration: const InputDecoration(
                      labelText: 'Backend URL',
                      hintText: 'http://your-server:8000',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _customUrl = value,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _testing ? null : _runTest,
                      icon: _testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(_testing ? 'Testing...' : 'Test Connection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF68D377),
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Test Results
            if (_testResult != null) ...[
              _buildSection(
                'Connection Test Result',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _testResult!['success'] == true
                              ? Icons.check_circle
                              : Icons.error,
                          color: _testResult!['success'] == true
                              ? Colors.green
                              : Colors.red,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _testResult!['success'] == true
                                ? 'Connected!'
                                : 'Connection Failed',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _testResult!['success'] == true
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('URL', _testResult!['url'].toString()),
                    if (_testResult!['statusCode'] != 0)
                      _buildInfoRow('Status Code', _testResult!['statusCode'].toString()),
                    if (_testResult!['responseTime'] != 0)
                      _buildInfoRow('Response Time', '${_testResult!['responseTime']}ms'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _testResult!['message'].toString(),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Network Info
            if (_networkInfo != null) ...[
              _buildSection(
                'Network Information',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Internet',
                      _networkInfo!['hasInternet'] == true ? '✓ Connected' : '✗ No connection',
                    ),
                    _buildInfoRow(
                      'IPv6 Support',
                      _networkInfo!['hasIPv6'] == true ? '✓ Yes' : '✗ No',
                    ),
                    if (_networkInfo!['interfaces'] != null) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Network Interfaces:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      ..._buildNetworkInterfaces(_networkInfo!['interfaces']),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Troubleshooting Tips
            _buildSection(
              'Troubleshooting Tips',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTip('1. Pastikan backend server sudah running'),
                  _buildTip('2. Cek firewall tidak memblokir port 8000'),
                  _buildTip('3. Untuk IPv6, pastikan network support IPv6'),
                  _buildTip('4. Coba gunakan IPv4 atau domain name'),
                  _buildTip('5. Untuk real device, gunakan IP yang sama network'),
                  const SizedBox(height: 12),
                  const Text(
                    'Common URLs:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildUrlExample('Android Emulator', 'http://10.0.2.2:8000'),
                  _buildUrlExample('iOS Simulator', 'http://localhost:8000'),
                  _buildUrlExample('Real Device (LAN)', 'http://192.168.x.x:8000'),
                  _buildUrlExample('VPS IPv6', 'http://[2407:6ac0:3:9d:abcd::1eb]:8000'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNetworkInterfaces(List<dynamic> interfaces) {
    return interfaces.map<Widget>((interface) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• ${interface['name']}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            ...((interface['addresses'] as List).map((addr) {
              return Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  '${addr['address']} (${addr['type']})',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              );
            })),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        tip,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildUrlExample(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label: $url',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('URL copied!')),
              );
            },
          ),
        ],
      ),
    );
  }
}
