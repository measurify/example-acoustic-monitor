class AppConfig {
  AppConfig._();

  static const String appTitle = 'Acoustic Thesis Monitor';

  // --- WEBSOCKET ESP32 ---
  static const String websocketUrl = 'ws://192.168.45.150/ws';
  static const String websocketIp = '192.168.45.150';
  static const int websocketPort = 81;

  // --- MEASURIFY CONFIGURATION ---
  static const String measurifyBaseUrl = 'https://tracker.elioslab.net/v1/measurements';
  static const String measurifyUsername = 'Corsini';
  static const String measurifyPassword = 'Corsini_Password';
  static const String measurifyTenant = 'Audio';
  
  // Entità obbligatorie secondo le specifiche Measurify
  static final String measurifyMeasurementId = 'session_test_${DateTime.now().millisecondsSinceEpoch}';
  static const String measurifyThing = 'RoomA';
  static const String measurifyFeature = 'Audio_recording';
  static const String measurifyDevice = 'Audio_Device';

  // Token del dispositivo
  static const String measurifyDeviceToken = 'DVC eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkZXZpY2UiOnsiX2lkIjoiQXVkaW9fRGV2aWNlIiwiZmVhdHVyZXMiOlsiQXVkaW9fcmVjb3JkaW5nIl0sInRoaW5ncyI6WyJSb29tQSJdLCJ2aXNpYmlsaXR5IjoicHVibGljIiwib3duZXIiOiI2YTY4Njg4NjRhM2JmODAwMWVjYzJjZDUifSwidGVuYW50Ijp7InBhc3N3b3JkaGFzaCI6dHJ1ZSwiX2lkIjoiQXVkaW8iLCJvcmdhbml6YXRpb24iOiJNZWFzdXJpZnkgb3JnIiwiYWRkcmVzcyI6Ik1lYXN1cmlmeSBTdHJlZXQsIEdlbm92YSIsImVtYWlsIjoibWF0dGVvLmZyZXN0YUBlZHUudW5pZ2UuaXQiLCJwaG9uZSI6IjUiLCJkYXRhYmFzZSI6IkF1ZGlvIn0sImlhdCI6MTc4NTIyNzg4NiwiZXhwIjozMzM0MjgyNzg4Nn0.6RMVodrbxL7ZpPBsrO9XsDnvUbPPXSKjnwJNR581uj8';

  // --- SOGLIE E TIMING ---
  static const int disconnectToleranceMs = 1500; 
  static const int maxChartPoints = 60;
  static const int reconnectDelaySeconds = 3;

  static const double warningDbThreshold = 75.0;
  static const double criticalDbThreshold = 85.0;
  static const double vibrationThreshold = 20.0;
  static const double larsenDbThreshold = 70.0;
  static const double larsenPeakMultiplier = 5.0;

  static const List<String> availableDevices = [
    'Audio_Device',
  ];
}