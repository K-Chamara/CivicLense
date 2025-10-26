import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class PDFViewerWidget extends StatelessWidget {
  final String documentUrl;
  final String documentName;

  const PDFViewerWidget({
    super.key,
    required this.documentUrl,
    required this.documentName,
  });

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
          // Header
          Row(
            children: [
              Icon(
                Icons.picture_as_pdf,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      documentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PDF Document',
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
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openInBrowser(context),
                  icon: const Icon(Icons.open_in_browser, size: 18),
                  label: const Text('Open in Browser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _downloadPDF(context),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyUrlToClipboard(context),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy URL'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showUrlInfo(context),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('URL Info'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _openInBrowser(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Opening PDF...'),
            ],
          ),
        ),
      );

      // Check if it's a Cloudinary URL and optimize it
      String optimizedUrl = _optimizeCloudinaryUrl(documentUrl);
      final uri = Uri.parse(optimizedUrl);
      
      // Try different approaches for opening PDFs
      bool launched = false;
      
      // First try: External application (bypass WebView crash)
      if (await canLaunchUrl(uri)) {
        try {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          launched = true;
        } catch (e) {
          print('External application failed: $e');
        }
      }
      
      // Second try: Platform default
      if (!launched && await canLaunchUrl(uri)) {
        try {
          await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
          launched = true;
        } catch (e) {
          print('Platform default failed: $e');
        }
      }
      
      // Third try: In-app web view (last resort - may crash)
      if (!launched && await canLaunchUrl(uri)) {
        try {
          await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
            webViewConfiguration: const WebViewConfiguration(
              enableJavaScript: true,
              enableDomStorage: true,
            ),
          );
          launched = true;
        } catch (e) {
          print('In-app web view failed: $e');
        }
      }
      
      Navigator.of(context).pop(); // Close loading dialog
      
      if (!launched) {
        _showErrorDialog(context, 'Cannot open PDF. The document might be corrupted or the URL is invalid.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF opened successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog(context, 'Error opening PDF: $e');
    }
  }

  String _optimizeCloudinaryUrl(String url) {
    try {
      // Check if it's a Cloudinary URL
      if (url.contains('res.cloudinary.com')) {
        // Add parameters to optimize for mobile viewing
        final uri = Uri.parse(url);
        
        // Add mobile-friendly parameters
        final optimizedParams = Map<String, String>.from(uri.queryParameters);
        optimizedParams['f_auto'] = 'true'; // Auto format
        optimizedParams['q_auto'] = 'true'; // Auto quality
        optimizedParams['fl_immutable_cache'] = 'true'; // Cache optimization
        
        // Rebuild the URL with optimized parameters
        return uri.replace(queryParameters: optimizedParams).toString();
      }
      
      return url; // Return original URL if not Cloudinary
    } catch (e) {
      print('Error optimizing URL: $e');
      return url; // Return original URL on error
    }
  }

  Future<void> _downloadPDF(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Preparing download...'),
            ],
          ),
        ),
      );

      final uri = Uri.parse(documentUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF download initiated'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog(context, 'Cannot download PDF');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog(context, 'Error downloading PDF: $e');
    }
  }

  Future<void> _copyUrlToClipboard(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: documentUrl));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF URL copied to clipboard'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _showErrorDialog(context, 'Error copying URL: $e');
    }
  }

  void _showUrlInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Document Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Document Name: $documentName'),
            const SizedBox(height: 8),
            Text('File Type: PDF'),
            const SizedBox(height: 8),
            const Text('Original URL:', style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(
              documentUrl,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text('Optimized URL:', style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(
              _optimizeCloudinaryUrl(documentUrl),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              'Troubleshooting Tips:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• If the PDF doesn\'t open, try copying the URL and opening it in your browser'),
            const Text('• Make sure you have a PDF viewer installed on your device'),
            const Text('• Check your internet connection'),
            const Text('• The document might be temporarily unavailable'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _copyUrlToClipboard(context);
            },
            child: const Text('Copy URL'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Access Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              'This usually means:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• The document URL has expired'),
            const Text('• The document was deleted from Cloudinary'),
            const Text('• There\'s a temporary network issue'),
            const SizedBox(height: 16),
            const Text(
              'Try These Solutions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Copy the URL and open it in your browser'),
            const Text('• Ask the user to re-upload the document'),
            const Text('• Check your internet connection'),
            const Text('• Contact the document owner'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _copyUrlToClipboard(context);
            },
            child: const Text('Copy URL'),
          ),
        ],
      ),
    );
  }
}
