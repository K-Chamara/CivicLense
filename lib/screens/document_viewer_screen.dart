import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentViewerScreen extends StatefulWidget {
  final String documentUrl;
  final String documentName;

  const DocumentViewerScreen({
    Key? key,
    required this.documentUrl,
    required this.documentName,
  }) : super(key: key);

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _openDocument();
  }

  Future<void> _openDocument() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Uri url = Uri.parse(widget.documentUrl);
      
      // Try different launch modes
      bool launched = false;
      
      // First try: External application
      if (await canLaunchUrl(url)) {
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
        print('✅ Launched with external application: $launched');
      }
      
      // If that fails, try platform default
      if (!launched && await canLaunchUrl(url)) {
        launched = await launchUrl(url, mode: LaunchMode.platformDefault);
        print('✅ Launched with platform default: $launched');
      }
      
      // If still fails, try in-app browser
      if (!launched && await canLaunchUrl(url)) {
        launched = await launchUrl(url, mode: LaunchMode.inAppWebView);
        print('✅ Launched with in-app web view: $launched');
      }
      
      if (!launched) {
        if (mounted) {
          _showUrlDialog();
        }
      } else {
        // If successfully launched, go back
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('❌ Error opening document: $e');
      if (mounted) {
        _showUrlDialog();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showUrlDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Viewer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Unable to open document automatically. You can:'),
            const SizedBox(height: 16),
            const Text('1. Copy the URL below'),
            const Text('2. Paste it in your browser'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                widget.documentUrl,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openDocument(); // Try again
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.documentName,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _openDocument,
            tooltip: 'Try Again',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Opening document...'),
            ] else ...[
              const Icon(
                Icons.description,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Document: ${widget.documentName}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'The document should open in your default browser or PDF viewer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openDocument,
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open Document'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Go Back'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
