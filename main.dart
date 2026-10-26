import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'controllers/monitoring_controller.dart';
import 'screens/dashboard_screen.dart';
import 'services/websocket_service.dart';
import 'services/measurify_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AcousticMonitorApp());
}

class AcousticMonitorApp extends StatefulWidget {
  const AcousticMonitorApp({super.key});

  @override
  State<AcousticMonitorApp> createState() => _AcousticMonitorAppState();
}

class _AcousticMonitorAppState extends State<AcousticMonitorApp> {
  late final MonitoringController controller;

  @override
  void initState() {
    super.initState();
    controller = MonitoringController(
      websocketService: WebSocketService(),
      measurifyService: MeasurifyService(), // Inizializzato senza baseUrl nel costruttore
    )..initialize(); // Avvia l'inizializzazione e la connessione WebSocket
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: DashboardScreen(controller: controller),
    );
  }
}