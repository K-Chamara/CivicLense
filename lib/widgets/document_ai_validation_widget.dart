import 'package:flutter/material.dart';
import '../services/document_validation_ai_service.dart';

class DocumentAIValidationWidget extends StatefulWidget {
  final String userId;
  final List<String> documents;
  final String userRole;
  final Function(BatchValidationResult) onValidationComplete;

  const DocumentAIValidationWidget({
    super.key,
    required this.userId,
    required this.documents,
    required this.userRole,
    required this.onValidationComplete,
  });

  @override
  State<DocumentAIValidationWidget> createState() => _DocumentAIValidationWidgetState();
}

class _DocumentAIValidationWidgetState extends State<DocumentAIValidationWidget> {
  bool _isValidating = false;
  BatchValidationResult? _validationResult;
  String _currentStatus = 'Ready to validate';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.purple, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Document Validation',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status and Progress
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isValidating ? Icons.hourglass_empty : Icons.info_outline,
                        color: Colors.purple,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _currentStatus,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  if (_isValidating) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(
                      backgroundColor: Colors.purple,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'AI is analyzing documents for authenticity...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Document List
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Documents to Validate:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.documents.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.description,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Document ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (_validationResult != null) ...[
                                const SizedBox(width: 8),
                                _buildValidationIcon(index),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Validation Results
            if (_validationResult != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getOverallColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getOverallColor().withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getOverallIcon(),
                          color: _getOverallColor(),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Overall Recommendation: ${_validationResult!.overallRecommendation}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getOverallColor(),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Confidence Score: ${(_validationResult!.overallConfidence * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Documents Analyzed: ${_validationResult!.analyzedDocuments}/${_validationResult!.totalDocuments}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_validationResult!.hasHighRiskDocuments) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '⚠️ High-risk documents detected',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isValidating ? null : _startValidation,
                    icon: const Icon(Icons.psychology, size: 18),
                    label: const Text('Start AI Validation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _validationResult != null ? _showDetailedResults : null,
                    icon: const Icon(Icons.analytics, size: 18),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Test Connection Button (for debugging)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _testConnection,
                icon: const Icon(Icons.wifi, size: 16),
                label: const Text('Test API Connection'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationIcon(int index) {
    if (_validationResult == null || index >= _validationResult!.individualResults.length) {
      return const Icon(Icons.help_outline, color: Colors.grey, size: 16);
    }

    final result = _validationResult!.individualResults[index];
    Color color;
    IconData icon;

    switch (result.verdict) {
      case 'APPROVED':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'SUSPICIOUS':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case 'LIKELY_FAKE':
      case 'REJECT':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Icon(icon, color: color, size: 16);
  }

  Color _getOverallColor() {
    if (_validationResult == null) return Colors.grey;
    
    switch (_validationResult!.overallRecommendation) {
      case 'APPROVE':
        return Colors.green;
      case 'REQUEST_CLARIFICATION':
        return Colors.orange;
      case 'REJECT':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getOverallIcon() {
    if (_validationResult == null) return Icons.help_outline;
    
    switch (_validationResult!.overallRecommendation) {
      case 'APPROVE':
        return Icons.check_circle;
      case 'REQUEST_CLARIFICATION':
        return Icons.warning;
      case 'REJECT':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _startValidation() async {
    setState(() {
      _isValidating = true;
      _currentStatus = 'Validating documents...';
    });

    try {
      final result = await DocumentValidationAIService.analyzeBatchDocuments(
        documentUrls: widget.documents,
        userRole: widget.userRole,
      );

      setState(() {
        _validationResult = result;
        _isValidating = false;
        _currentStatus = 'Validation completed';
      });

      // Call the completion callback
      widget.onValidationComplete(result);

    } catch (e) {
      setState(() {
        _isValidating = false;
        _currentStatus = 'Validation failed: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI validation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDetailedResults() {
    if (_validationResult == null) return;

    showDialog(
      context: context,
      builder: (context) => DetailedValidationResultsDialog(
        validationResult: _validationResult!,
        documents: widget.documents,
      ),
    );
  }

  Future<void> _testConnection() async {
    try {
      setState(() {
        _currentStatus = 'Testing API connection...';
      });

      final isConnected = await DocumentValidationAIService.testConnection();
      
      setState(() {
        _currentStatus = isConnected ? 'API connection successful' : 'API connection failed';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isConnected ? 'API connection successful!' : 'API connection failed'),
          backgroundColor: isConnected ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _currentStatus = 'API test failed: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class DetailedValidationResultsDialog extends StatelessWidget {
  final BatchValidationResult validationResult;
  final List<String> documents;

  const DetailedValidationResultsDialog({
    super.key,
    required this.validationResult,
    required this.documents,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Detailed Validation Results',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall Summary
                    _buildSummaryCard(),
                    const SizedBox(height: 20),
                    
                    // Individual Document Results
                    const Text(
                      'Individual Document Analysis:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    ...validationResult.individualResults.asMap().entries.map((entry) {
                      final index = entry.key;
                      final result = entry.value;
                      return _buildDocumentResultCard(index + 1, result);
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getOverallColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getOverallColor().withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getOverallIcon(),
                color: _getOverallColor(),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Overall Assessment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getOverallColor(),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Recommendation: ${validationResult.overallRecommendation}'),
          Text('Confidence: ${(validationResult.overallConfidence * 100).toStringAsFixed(1)}%'),
          Text('Documents Analyzed: ${validationResult.analyzedDocuments}/${validationResult.totalDocuments}'),
          if (validationResult.hasHighRiskDocuments)
            const Text('⚠️ High-risk documents detected', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildDocumentResultCard(int documentNumber, DocumentValidationResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getVerdictIcon(result.verdict),
                color: _getVerdictColor(result.verdict),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Document $documentNumber',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getVerdictColor(result.verdict).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.verdict,
                  style: TextStyle(
                    color: _getVerdictColor(result.verdict),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Document Type: ${result.documentType}'),
          Text('Confidence: ${(result.confidenceScore * 100).toStringAsFixed(1)}%'),
          Text('Risk Level: ${result.riskLevel}'),
          if (result.documentDescription.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Document Description:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(result.documentDescription),
          ],
          if (result.whatsLacking.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('What\'s Lacking:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(result.whatsLacking),
          ],
          if (result.approvalRecommendation.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('AI Recommendation:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(result.approvalRecommendation),
          ],
          if (result.reasoning.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Reasoning:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(result.reasoning),
          ],
          if (result.adminNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Admin Notes: ${result.adminNotes}'),
          ],
          if (result.redFlags.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Red Flags:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...result.redFlags.map((flag) => Text('• $flag')),
          ],
          if (result.positiveIndicators.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Positive Indicators:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...result.positiveIndicators.map((indicator) => Text('• $indicator')),
          ],
        ],
      ),
    );
  }

  Color _getOverallColor() {
    switch (validationResult.overallRecommendation) {
      case 'APPROVE':
        return Colors.green;
      case 'REQUEST_CLARIFICATION':
        return Colors.orange;
      case 'REJECT':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getOverallIcon() {
    switch (validationResult.overallRecommendation) {
      case 'APPROVE':
        return Icons.check_circle;
      case 'REQUEST_CLARIFICATION':
        return Icons.warning;
      case 'REJECT':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getVerdictColor(String verdict) {
    switch (verdict) {
      case 'APPROVED':
        return Colors.green;
      case 'SUSPICIOUS':
        return Colors.orange;
      case 'LIKELY_FAKE':
      case 'REJECT':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getVerdictIcon(String verdict) {
    switch (verdict) {
      case 'APPROVED':
        return Icons.check_circle;
      case 'SUSPICIOUS':
        return Icons.warning;
      case 'LIKELY_FAKE':
      case 'REJECT':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}