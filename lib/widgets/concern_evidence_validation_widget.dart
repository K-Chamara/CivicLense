import 'package:flutter/material.dart';
import '../services/concern_evidence_validation_service.dart';

/// Widget for AI validation of concern evidence images
class ConcernEvidenceValidationWidget extends StatefulWidget {
  final String concernId;
  final String concernTitle;
  final String concernDescription;
  final List<String> evidenceUrls;
  final Function(EvidenceValidationResult)? onValidationComplete;

  const ConcernEvidenceValidationWidget({
    super.key,
    required this.concernId,
    required this.concernTitle,
    required this.concernDescription,
    required this.evidenceUrls,
    this.onValidationComplete,
  });

  @override
  State<ConcernEvidenceValidationWidget> createState() => _ConcernEvidenceValidationWidgetState();
}

class _ConcernEvidenceValidationWidgetState extends State<ConcernEvidenceValidationWidget> {
  bool _isValidating = false;
  List<EvidenceValidationResult> _results = [];
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _startValidation();
  }

  Future<void> _startValidation() async {
    if (widget.evidenceUrls.isEmpty) {
      setState(() {
        _currentStatus = 'No evidence images to validate';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _currentStatus = 'Starting AI validation...';
    });

    try {
      // Analyze all evidence images
      final results = await ConcernEvidenceValidationService.analyzeMultipleEvidence(
        imageUrls: widget.evidenceUrls,
        concernTitle: widget.concernTitle,
        concernDescription: widget.concernDescription,
      );

      setState(() {
        _results = results;
        _isValidating = false;
        _currentStatus = 'Validation completed';
      });

      // Notify parent widget
      if (widget.onValidationComplete != null && results.isNotEmpty) {
        widget.onValidationComplete!(results.first);
      }
    } catch (e) {
      setState(() {
        _isValidating = false;
        _currentStatus = 'Validation failed: $e';
      });
    }
  }

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
            // Header
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Evidence Validation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Analyzing ${widget.evidenceUrls.length} evidence image(s)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status
            if (_isValidating) ...[
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _currentStatus,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ] else if (_results.isNotEmpty) ...[
              // Results
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    return _buildEvidenceResultCard(result, index + 1);
                  },
                ),
              ),
            ] else ...[
              // No results
              Expanded(
                child: Center(
                  child: Text(
                    _currentStatus,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                if (_results.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _showDetailedReport(),
                    child: const Text('View Detailed Report'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceResultCard(EvidenceValidationResult result, int evidenceNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: result.recommendationColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: result.recommendationColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: result.recommendationColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.overallRecommendation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Evidence $evidenceNumber',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '${(result.confidence * 100).toStringAsFixed(0)}% Confidence',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Evidence Type and Description
          Text(
            'Type: ${result.evidenceType.toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            result.description,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),

          // Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricChip(
                  'Authenticity',
                  result.authenticity,
                  result.authenticityScore,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricChip(
                  'Relevance',
                  result.relevance,
                  result.relevanceScore,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricChip(
                  'Quality',
                  result.quality,
                  result.qualityScore,
                  Colors.orange,
                ),
              ),
            ],
          ),

          // Red Flags
          if (result.redFlags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Red Flags',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...result.redFlags.map((flag) => Text(
                    '• $flag',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                    ),
                  )),
                ],
              ),
            ),
          ],

          // Recommendations
          if (result.recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Recommendations',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...result.recommendations.map((rec) => Text(
                    '• $rec',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, double score, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
          Text(
            '${(score * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailedReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detailed Evidence Report'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _results.asMap().entries.map((entry) {
              final index = entry.key;
              final result = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evidence ${index + 1} - ${result.evidenceType.toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Description: ${result.description}'),
                    const SizedBox(height: 8),
                    Text('Authenticity: ${result.authenticity} (${(result.authenticityScore * 100).toStringAsFixed(0)}%)'),
                    Text('Relevance: ${result.relevance} (${(result.relevanceScore * 100).toStringAsFixed(0)}%)'),
                    Text('Quality: ${result.quality} (${(result.qualityScore * 100).toStringAsFixed(0)}%)'),
                    Text('Investigative Value: ${result.investigativeValue}'),
                    Text('Confidence: ${(result.confidence * 100).toStringAsFixed(0)}%'),
                    if (result.redFlags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Red Flags: ${result.redFlags.join(', ')}'),
                    ],
                    if (result.recommendations.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Recommendations: ${result.recommendations.join(', ')}'),
                    ],
                    if (result.legalImplications.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Legal Implications: ${result.legalImplications.join(', ')}'),
                    ],
                    if (result.followUpActions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Follow-up Actions: ${result.followUpActions.join(', ')}'),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
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
}
