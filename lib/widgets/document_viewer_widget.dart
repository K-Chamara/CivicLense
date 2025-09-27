import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
      final uri = Uri.parse(documentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorDialog(context, 'Cannot open document');
      }
    } catch (e) {
      _showErrorDialog(context, 'Error opening document: $e');
    }
  }

  Future<void> _downloadDocument(BuildContext context) async {
    try {
      final uri = Uri.parse(documentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorDialog(context, 'Cannot download document');
      }
    } catch (e) {
      _showErrorDialog(context, 'Error downloading document: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
