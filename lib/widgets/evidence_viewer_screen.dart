import 'package:flutter/material.dart';
import '../models/concern_models.dart';

class EvidenceViewerScreen extends StatefulWidget {
  final List<ConcernAttachment> attachments;
  final String concernTitle;

  const EvidenceViewerScreen({
    super.key,
    required this.attachments,
    required this.concernTitle,
  });

  @override
  State<EvidenceViewerScreen> createState() => _EvidenceViewerScreenState();
}

class _EvidenceViewerScreenState extends State<EvidenceViewerScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Evidence: ${widget.concernTitle}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showFileInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // File counter and navigation
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'File ${_currentIndex + 1} of ${widget.attachments.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentIndex > 0 ? _previousFile : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentIndex < widget.attachments.length - 1 ? _nextFile : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // File content display
          Expanded(
            child: _buildFileContent(),
          ),
          
          // File list at bottom
          Container(
            height: 100,
            padding: const EdgeInsets.all(8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.attachments.length,
              itemBuilder: (context, index) {
                final attachment = widget.attachments[index];
                final isSelected = index == _currentIndex;
                
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildThumbnail(attachment),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileContent() {
    final currentAttachment = widget.attachments[_currentIndex];
    
    if (currentAttachment.fileType.toLowerCase() == 'image') {
      return _buildImageView(currentAttachment);
    } else if (currentAttachment.fileType.toLowerCase() == 'pdf') {
      return _buildPdfView(currentAttachment);
    } else {
      return _buildGenericFileView(currentAttachment);
    }
  }

  Widget _buildImageView(ConcernAttachment attachment) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            attachment.fileUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Try to reload
                        setState(() {});
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPdfView(ConcernAttachment attachment) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.picture_as_pdf,
            size: 100,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            attachment.fileName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'PDF File',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openFile(attachment.fileUrl),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericFileView(ConcernAttachment attachment) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileTypeIcon(attachment.fileType),
            size: 100,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          Text(
            attachment.fileName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${attachment.fileType.toUpperCase()} File',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Size: ${_formatFileSize(attachment.fileSize)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openFile(attachment.fileUrl),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(ConcernAttachment attachment) {
    if (attachment.fileType.toLowerCase() == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          attachment.fileUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Icon(
                Icons.image,
                color: Colors.grey[400],
              ),
            );
          },
        ),
      );
    } else {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Icon(
            _getFileTypeIcon(attachment.fileType),
            color: Colors.grey[600],
          ),
        ),
      );
    }
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'image':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'document':
        return Icons.description;
      case 'text':
        return Icons.text_snippet;
      default:
        return Icons.attach_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _previousFile() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _nextFile() {
    if (_currentIndex < widget.attachments.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _showFileInfo() {
    final attachment = widget.attachments[_currentIndex];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${attachment.fileName}'),
            const SizedBox(height: 8),
            Text('Type: ${attachment.fileType.toUpperCase()}'),
            const SizedBox(height: 8),
            Text('Size: ${_formatFileSize(attachment.fileSize)}'),
            const SizedBox(height: 8),
            Text('Uploaded: ${_formatDateTime(attachment.uploadedAt)}'),
            const SizedBox(height: 8),
            Text('URL: ${attachment.fileUrl}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openFile(String url) {
    // TODO: Implement file opening logic
    // For now, show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening file: $url'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
