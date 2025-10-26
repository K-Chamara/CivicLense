import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NetworkDiagnosticWidget extends StatefulWidget {
  const NetworkDiagnosticWidget({super.key});

  @override
  State<NetworkDiagnosticWidget> createState() => _NetworkDiagnosticWidgetState();
}

class _NetworkDiagnosticWidgetState extends State<NetworkDiagnosticWidget> {
  bool _isRunning = false;
  Map<String, String> _results = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.network_check,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Network Diagnostic',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRunning ? null : _runDiagnostics,
              icon: _isRunning 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow, size: 18),
              label: Text(_isRunning ? 'Running Tests...' : 'Run Network Tests'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Test Results:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ..._results.entries.map((entry) => 
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(entry.value).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(entry.value).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(entry.value),
                      color: _getStatusColor(entry.value),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.value,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          const Text(
            'Troubleshooting Tips:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• If DNS tests fail, restart your emulator with: emulator -avd your_avd_name -dns-server 8.8.8.8',
            style: TextStyle(fontSize: 12),
          ),
          const Text(
            '• Check your internet connection on the host machine',
            style: TextStyle(fontSize: 12),
          ),
          const Text(
            '• Try using a different emulator or physical device',
            style: TextStyle(fontSize: 12),
          ),
          const Text(
            '• Ensure firewall is not blocking the emulator',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunning = true;
      _results.clear();
    });

    // Test DNS resolution
    await _testDNSResolution();
    
    // Test HTTP connectivity
    await _testHTTPConnectivity();
    
    // Test specific services
    await _testFirebaseConnectivity();
    await _testCloudinaryConnectivity();

    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _testDNSResolution() async {
    try {
      // Test basic DNS resolution
      final uri = Uri.parse('https://google.com');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        _results['DNS Resolution'] = '✅ Working - Can resolve hostnames';
      } else {
        _results['DNS Resolution'] = '⚠️ Partial - DNS works but HTTP issues';
      }
    } catch (e) {
      _results['DNS Resolution'] = '❌ Failed - Cannot resolve hostnames: ${e.toString()}';
    }
  }

  Future<void> _testHTTPConnectivity() async {
    try {
      final uri = Uri.parse('https://httpbin.org/get');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        _results['HTTP Connectivity'] = '✅ Working - Can make HTTP requests';
      } else {
        _results['HTTP Connectivity'] = '⚠️ Partial - HTTP requests have issues';
      }
    } catch (e) {
      _results['HTTP Connectivity'] = '❌ Failed - Cannot make HTTP requests: ${e.toString()}';
    }
  }

  Future<void> _testFirebaseConnectivity() async {
    try {
      final uri = Uri.parse('https://firestore.googleapis.com');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 404) {
        _results['Firebase Firestore'] = '✅ Working - Can reach Firebase servers';
      } else {
        _results['Firebase Firestore'] = '⚠️ Partial - Firebase connectivity issues';
      }
    } catch (e) {
      _results['Firebase Firestore'] = '❌ Failed - Cannot reach Firebase: ${e.toString()}';
    }
  }

  Future<void> _testCloudinaryConnectivity() async {
    try {
      final uri = Uri.parse('https://res.cloudinary.com');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 404) {
        _results['Cloudinary'] = '✅ Working - Can reach Cloudinary servers';
      } else {
        _results['Cloudinary'] = '⚠️ Partial - Cloudinary connectivity issues';
      }
    } catch (e) {
      _results['Cloudinary'] = '❌ Failed - Cannot reach Cloudinary: ${e.toString()}';
    }
  }

  Color _getStatusColor(String status) {
    if (status.startsWith('✅')) return Colors.green;
    if (status.startsWith('⚠️')) return Colors.orange;
    if (status.startsWith('❌')) return Colors.red;
    return Colors.grey;
  }

  IconData _getStatusIcon(String status) {
    if (status.startsWith('✅')) return Icons.check_circle;
    if (status.startsWith('⚠️')) return Icons.warning;
    if (status.startsWith('❌')) return Icons.error;
    return Icons.help;
  }
}
