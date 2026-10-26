import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RecordButton extends StatelessWidget {
  final bool isRecording;
  final String elapsedLabel;
  final VoidCallback onPressed;

  const RecordButton({
    super.key,
    required this.isRecording,
    required this.elapsedLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: isRecording ? AppTheme.red : AppTheme.cyan,
          foregroundColor: AppTheme.background,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(isRecording
            ? Icons.stop_circle_rounded
            : Icons.fiber_manual_record_rounded),
        label: Text(
          isRecording
              ? 'Ferma registrazione • $elapsedLabel'
              : 'Avvia registrazione dati',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
