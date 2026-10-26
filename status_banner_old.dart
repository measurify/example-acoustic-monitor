import 'package:flutter/material.dart';
import '../models/alarm_state.dart';
import '../theme/app_theme.dart';

class StatusBanner extends StatelessWidget {
  final AlarmState alarmState;
  final String connectionLabel;

  const StatusBanner({
    super.key,
    required this.alarmState,
    required this.connectionLabel,
  });

  Color _resolveColor() {
    switch (alarmState.level) {
      case AlarmLevel.nominal:
        return AppTheme.green;
      case AlarmLevel.warning:
        return AppTheme.orange;
      case AlarmLevel.critical:
        return AppTheme.red;
      case AlarmLevel.larsen:
        return AppTheme.purple;
      case AlarmLevel.vibration:
        return AppTheme.orange;
      case AlarmLevel.offline:
        return AppTheme.red;
    }
  }

  IconData _resolveIcon() {
    switch (alarmState.level) {
      case AlarmLevel.nominal:
        return Icons.check_circle_outline_rounded;
      case AlarmLevel.warning:
        return Icons.warning_amber_rounded;
      case AlarmLevel.critical:
        return Icons.error_outline_rounded;
      case AlarmLevel.larsen:
        return Icons.graphic_eq_rounded;
      case AlarmLevel.vibration:
        return Icons.vibration_rounded;
      case AlarmLevel.offline:
        return Icons.wifi_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _resolveColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(_resolveIcon(), color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  alarmState.title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alarmState.description,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stato rete: $connectionLabel',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
