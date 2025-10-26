import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class DocumentViewerWidget extends StatelessWidget {
  final String documentUrl;
  final String documentName;

  const DocumentViewerWidget({
    super.key,
    required this.documentUrl,
    required this.documentName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            _getDocumentIcon(documentUrl),
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  documentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getFileType(documentUrl),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _viewDocument(context),
            icon: const Icon(
              Icons.visibility,
              color: Colors.blue,
              size: 20,
            ),
            tooltip: 'View Document',
          ),
          IconButton(
            onPressed: () => _downloadDocument(context),
            icon: const Icon(
              Icons.download,
              color: Colors.green,
              size: 20,
            ),
            tooltip: 'Download Document',
          ),
          IconButton(
            onPressed: () => _copyUrlToClipboard(context),
            icon: const Icon(
              Icons.copy,
              color: Colors.orange,
              size: 20,
            ),
            tooltip: 'Copy URL',
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon(String url) {
    final extension = _getFileType(url).toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileType(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final fileName = pathSegments.last;
        final dotIndex = fileName.lastIndexOf('.');
        if (dotIndex != -1 && dotIndex < fileName.length - 1) {
          return fileName.substring(dotIndex + 1).toUpperCase();
        }
      }
    } catch (e) {
      // If parsing fails, try to extract from URL string
      final dotIndex = url.lastIndexOf('.');
      if (dotIndex != -1 && dotIndex < url.length - 1) {
        return url.substring(dotIndex + 1).toUpperCase();
      }
    }
    return 'FILE';
  }

  Future<void> _viewDocument(BuildContext context) async {
    try {
      final fileType = _getFileType(documentUrl).toLowerCase();
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Opening document...'),
            ],
          ),
        ),
      );

      // Optimize URL for Cloudinary if needed
      String optimizedUrl = _optimizeCloudinaryUrl(documentUrl);
      final uri = Uri.parse(optimizedUrl);
      
      if (fileType == 'pdf') {
        // For PDFs, try different launch modes
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
        
        if (!launched) {
          Navigator.of(context).pop(); // Close loading dialog
          _showErrorDialog(context, 'Cannot open PDF document. Please try downloading it instead.');
        } else {
          Navigator.of(context).pop(); // Close loading dialog
        }
        
      } else if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileType)) {
        // For images, try to open in external application
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          Navigator.of(context).pop(); // Close loading dialog
        } else {
          Navigator.of(context).pop(); // Close loading dialog
          _showErrorDialog(context, 'Cannot open image document');
        }
      } else {
        // For other file types, try external application
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          Navigator.of(context).pop(); // Close loading dialog
        } else {
          Navigator.of(context).pop(); // Close loading dialog
          _showErrorDialog(context, 'Cannot open document');
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog(context, 'Error opening document: $e');
    }
  }

  Future<void> _downloadDocument(BuildContext context) async {
    try {
      final uri = Uri.parse(documentUrl);
      
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
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        Navigator.of(context).pop(); // Close loading dialog
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document download initiated'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog(context, 'Cannot download document');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog(context, 'Error downloading document: $e');
    }
  }

  Future<void> _copyUrlToClipboard(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: documentUrl));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document URL copied to clipboard'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _showErrorDialog(context, 'Error copying URL: $e');
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
            const Text('• The document requires authentication'),
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
