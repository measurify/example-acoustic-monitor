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
        return AppTheme.blue;
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

  String _resolveTag() {
    switch (alarmState.level) {
      case AlarmLevel.nominal:
        return 'Stabile';
      case AlarmLevel.warning:
        return 'Attenzione';
      case AlarmLevel.critical:
        return 'Critico';
      case AlarmLevel.larsen:
        return 'Feedback';
      case AlarmLevel.vibration:
        return 'Vibrazioni';
      case AlarmLevel.offline:
        return 'Offline';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.22),
            AppTheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_resolveIcon(), color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      alarmState.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _resolveTag(),
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  alarmState.description,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.wifi_tethering_rounded,
                      size: 15,
                      color: AppTheme.textSoft,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Rete: $connectionLabel',
                        style: const TextStyle(
                          color: AppTheme.textSoft,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
