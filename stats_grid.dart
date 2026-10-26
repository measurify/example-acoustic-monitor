import 'package:flutter/material.dart';

import '../controllers/monitoring_controller.dart';
import 'info_card.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key, required this.controller});

  final MonitoringController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _MetricTile(
                title: 'dB(A)',
                value: controller.currentDba.toStringAsFixed(1),
                subtitle: 'Livello sonoro attuale',
                color: const Color(0xFF34D399),
                icon: Icons.graphic_eq_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                title: 'Pacchetti',
                value: '${controller.packetsReceived}',
                subtitle: 'Ricezione dati',
                color: const Color(0xFF60A5FA),
                icon: Icons.wifi_tethering_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _MiniMetricTile(
                title: 'Acc X',
                value: controller.accX,
                color: const Color(0xFFFF7A59),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniMetricTile(
                title: 'Acc Y',
                value: controller.accY,
                color: const Color(0xFF34D399),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniMetricTile(
                title: 'Acc Z',
                value: controller.accZ,
                color: const Color(0xFF60A5FA),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(title, style: const TextStyle(color: Colors.white60)),
              Icon(icon, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _MiniMetricTile extends StatelessWidget {
  const _MiniMetricTile({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: title,
      child: Column(
        children: <Widget>[
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
