import 'package:flutter/material.dart';

import '../../data/repositories/user_safety_repository.dart';

class AiOutputReportButton extends StatefulWidget {
  const AiOutputReportButton({
    super.key,
    required this.feature,
    required this.outputId,
    required this.outputText,
    this.color,
    this.compact = false,
  });

  final String feature;
  final String outputId;
  final String outputText;
  final Color? color;
  final bool compact;

  @override
  State<AiOutputReportButton> createState() => _AiOutputReportButtonState();
}

class _AiOutputReportButtonState extends State<AiOutputReportButton> {
  bool _submitting = false;

  Future<void> _showReportDialog() async {
    var reason = 'incorrect';
    final detailsController = TextEditingController();
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Report AI output'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tell us what is wrong. Reports help us review and improve generated content.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: const [
                  DropdownMenuItem(
                      value: 'incorrect',
                      child: Text('Incorrect or misleading')),
                  DropdownMenuItem(
                      value: 'unsafe', child: Text('Unsafe advice')),
                  DropdownMenuItem(
                      value: 'offensive', child: Text('Offensive content')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => reason = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Details (optional)',
                  hintText: 'Describe the problem',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Submit report'),
            ),
          ],
        ),
      ),
    );

    if (shouldSubmit == true && mounted) {
      setState(() => _submitting = true);
      try {
        await UserSafetyRepository().reportAiOutput(
          feature: widget.feature,
          outputId: widget.outputId,
          reason: reason,
          details: detailsController.text,
          outputPreview: widget.outputText,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Thank you. The AI output was reported for review.')),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Sign in and try submitting the report again.')),
          );
        }
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }
    detailsController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitting) {
      return SizedBox.square(
        dimension: widget.compact ? 24 : 40,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      tooltip: 'Report AI output',
      visualDensity: widget.compact ? VisualDensity.compact : null,
      iconSize: widget.compact ? 18 : 24,
      color: widget.color,
      onPressed: _showReportDialog,
      icon: const Icon(Icons.flag_outlined),
    );
  }
}
