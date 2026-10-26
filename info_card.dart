import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
    this.highlightColor,
    this.compact = false,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;
  final Color? highlightColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = highlightColor ?? AppTheme.cyan;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.stroke),
        gradient: LinearGradient(
          colors: [
            AppTheme.surface,
            Color.lerp(AppTheme.surface, color, 0.08)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          SizedBox(height: compact ? 12 : 16),
          child,
        ],
      ),
    );
  }
}
