import 'package:flutter/material.dart';

import '../controllers/monitoring_controller.dart';
import 'info_card.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key, required this.controller});

  final MonitoringController controller;

  @override
  Widget build(BuildContext context) {
    final Color color = _connectionColor(controller.connectionState);

    return InfoCard(
      title: 'STATO CONNESSIONE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                controller.connectionLabel,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Endpoint: ${controller.websocketUrl}'),
          Text('Tentativi reconnect: ${controller.reconnectAttempt}'),
          Text('Pacchetti ricevuti: ${controller.packetsReceived}'),
          Text('Ultimo pacchetto: ${controller.lastPacketAt?.toIso8601String() ?? 'mai'}'),
          Text('Ultimo errore: ${controller.lastError.isEmpty ? '-' : controller.lastError}'),
        ],
      ),
    );
  }
}

Color _connectionColor(ConnectionStateView state) {
  switch (state) {
    case ConnectionStateView.connected:
      return const Color(0xFF34D399);
    case ConnectionStateView.connecting:
      return const Color(0xFFFBBF24);
    case ConnectionStateView.reconnecting:
      return const Color(0xFFF59E0B);
    case ConnectionStateView.error:
      return const Color(0xFFFF5D73);
    case ConnectionStateView.disconnected:
      return const Color(0xFFFF5D73);
  }
}
