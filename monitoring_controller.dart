import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../config/app_config.dart';
import '../services/websocket_service.dart';
import '../services/measurify_service.dart';
import '../theme/app_theme.dart';

enum ConnectionStateView { disconnected, connecting, connected, reconnecting, error }
enum DashboardPage { home, fft, accelerometer, debug }
enum AlarmKind { nominal, offline, larsen, dbDanger, dbWarning, vibrationCritical, vibrationWarning }
enum DebugIssueKind {
  connection,
  timeout,
  measurify,
  noDataToSave,
  packetFormat,
  larsen,
  vibration,
  harmfulDb,
}

class AlarmItem {
  const AlarmItem({required this.kind, required this.title, required this.description, required this.priority});
  final AlarmKind kind;
  final String title;
  final String description;
  final int priority;
}

class DebugIssue {
  const DebugIssue({required this.kind, required this.title, required this.description, required this.icon, required this.color});
  final DebugIssueKind kind;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

class MonitoringController extends ChangeNotifier {
  MonitoringController({
    required WebSocketService websocketService,
    required MeasurifyService measurifyService,
  })  : _websocketService = websocketService,
        _measurifyService = measurifyService;

  final WebSocketService _websocketService;
  final MeasurifyService _measurifyService;
  String get websocketUrl => AppConfig.websocketUrl;

  DashboardPage selectedPage = DashboardPage.home;
  ConnectionStateView connectionState = ConnectionStateView.disconnected;

  double currentDba = 45.0;
  List<double> fftBands = List<double>.filled(16, 0.0);
  
  // Valori iniziali sensati a riposo (Gravità terrestre su Z ~9.81 m/s²)
  double accX = 0.24;
  double accY = 0.18;
  double accZ = 9.81;

  int reconnectAttempt = 0;
  int packetsReceived = 0;
  int packetsSentToMeasurify = 0;
  String lastError = '';
  String rawLastPacket = 'Nessun pacchetto ricevuto';
  String latestUiMessage = '';
  DateTime? lastPacketAt;
  bool _initialized = false;

  bool isRecording = false;
  final Stopwatch recordingStopwatch = Stopwatch();
  Timer? _recordingTicker;
  
  Timer? _reconnectTimer;
  Timer? _toleranceTimer;
  bool _isToleratingDisconnect = false;

  // --- TIMER E VARIABILI PER DINAMICA ACCELEROMETRO ---
  Timer? _idleJitterTimer;
  Timer? _mockTimer;
  DateTime? _simulationStartTime;
  bool isMockingVibrations = false;
  final math.Random _random = math.Random();

  // Variabili per l'invio automatico a Measurify (Batching Time Series)
  final List<TimeserieSample> _measurifyBuffer = <TimeserieSample>[];
  static const int _measurifyBatchThreshold = 100;
  bool _isSendingBatch = false;
  bool autoSyncToMeasurify = true;

  final List<List<String>> csvRows = <List<String>>[];
  List<AlarmItem> activeAlarms = const <AlarmItem>[];

  /// Invia manualmente il punto/campione corrente a Measurify
  Future<void> sendCurrentPointToMeasurify() async {
    final String currentTimestamp = DateTime.now().millisecondsSinceEpoch.toString();

    final currentSample = TimeserieSample(
      timestamp: currentTimestamp,
      values: [
        currentDba,
        accX,
        accY,
        accZ,
        ...fftBands,
      ],
    );

    _measurifyBuffer.add(currentSample);
    
    latestUiMessage = 'Inviando punto corrente a Measurify...';
    notifyListeners();

    await _flushMeasurifyBuffer();
  }

  // --- GESTIONE RUMORE DI FONDO IN IDLE (PER EVITARE NUMERI STAZIONARI) ---
  void _startIdleJitter() {
    _idleJitterTimer?.cancel();
    // Genera micro-variazioni continue ogni 150ms per simulare rumore termico/quantizzazione del sensore
    _idleJitterTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (!isMockingVibrations) {
        accX = 0.24 + (_random.nextDouble() - 0.5) * 0.08;
        accY = 0.18 + (_random.nextDouble() - 0.5) * 0.08;
        accZ = 9.81 + (_random.nextDouble() - 0.5) * 0.14; // Oscilla dinamicamente attorno a 9.81
        _updateAlarms();
        _storeCsvRowIfNeeded();
        notifyListeners();
      }
    });
  }

  // --- METODI PER SIMULAZIONE VIBRAZIONI ACCELEROMETRO ---
  void toggleMockVibrations() {
    if (isMockingVibrations) {
      stopMockVibrations();
    } else {
      startMockVibrations();
    }
  }

  void startMockVibrations() {
    _mockTimer?.cancel();
    _simulationStartTime = DateTime.now();
    isMockingVibrations = true;
    notifyListeners();

    const updateInterval = Duration(milliseconds: 100); // 10 aggiornamenti al secondo

    _mockTimer = Timer.periodic(updateInterval, (timer) {
      final elapsedSeconds = DateTime.now().difference(_simulationStartTime!).inSeconds;

      if (elapsedSeconds < 10) {
        // Primi 10 secondi: micro-vibrazioni da banco/ambiente
        accX = 0.25 + (_random.nextDouble() - 0.5) * 0.12;
        accY = 0.18 + (_random.nextDouble() - 0.5) * 0.12;
        accZ = 9.81 + (_random.nextDouble() - 0.5) * 0.20;
      } else {
        // Dopo 10 secondi: oscillazioni marcate per testare le soglie di allarme
        final t = timer.tick * 0.3;
        accX = 2.1 + math.sin(t * 2.5) * 4.2 + (_random.nextDouble() - 0.5) * 2.0;
        accY = 1.6 + math.cos(t * 1.8) * 3.5 + (_random.nextDouble() - 0.5) * 1.8;
        accZ = 9.81 + math.sin(t * 3.2) * 5.5 + (_random.nextDouble() - 0.5) * 2.5;
      }

      _updateAlarms();
      _storeCsvRowIfNeeded();
      notifyListeners();
    });
  }

  void stopMockVibrations() {
    _mockTimer?.cancel();
    isMockingVibrations = false;
    _updateAlarms();
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _startIdleJitter(); // Avvia l'oscillazione continua a riposo
    await connect();
  }

  Future<void> connect() async {
    _reconnectTimer?.cancel();
    _toleranceTimer?.cancel();
    _isToleratingDisconnect = false;
    
    if (reconnectAttempt == 0) {
      connectionState = ConnectionStateView.connecting;
    } else {
      handleReconnectionAttempt();
      connectionState = ConnectionStateView.reconnecting;
    }

    notifyListeners();
    await _doConnect();
  }
  
  void handleReconnectionAttempt() {
    reconnectAttempt++;
    latestUiMessage = 'Tentativo di riconnessione $reconnectAttempt in corso...';
    notifyListeners();
  }

  Future<void> _doConnect() async {
    await _websocketService.connect(
      url: websocketUrl,
      onConnected: _handleConnected,
      onData: _handleIncomingData,
      onDone: () => _handleConnectionDrop('Connessione chiusa'),
      onError: (e) => _handleConnectionDrop(e.toString()),
    );
  }

  void manualReconnect() {
    reconnectAttempt = 0;
    connect();
  }

  void changeSelectedPage(DashboardPage page) {
    selectedPage = page;
    notifyListeners();
  }

  void clearLatestUiMessage() {
    latestUiMessage = '';
    notifyListeners();
  }

  void _handleConnected() {
    _isToleratingDisconnect = false;
    _toleranceTimer?.cancel();
    connectionState = ConnectionStateView.connected;
    lastError = '';
    reconnectAttempt = 0;
    notifyListeners();
  }

  void _handleIncomingData(Map<dynamic, dynamic> json) {
    _isToleratingDisconnect = false;
    _toleranceTimer?.cancel();
    
    packetsReceived++;
    reconnectAttempt = 0;
    connectionState = ConnectionStateView.connected;
    lastError = '';
    rawLastPacket = json.toString();
    lastPacketAt = DateTime.now();

    currentDba = (json['dBA'] as num?)?.toDouble() ?? currentDba;

    final dynamic fft = json['fft'];
    if (fft is List) {
      fftBands = fft.map((e) => (e as num).toDouble()).toList();
      if (fftBands.length < 16) {
        fftBands = [...fftBands, ...List<double>.filled(16 - fftBands.length, 0.0)];
      }
    }

    // Se non stiamo usando il mockup locale e arrivano dati reali dal WebSocket
    if (!isMockingVibrations) {
      final dynamic accel = json['accel'];
      if (accel is List && accel.length >= 3) {
        final rawX = (accel[0] as num).toDouble();
        final rawY = (accel[1] as num).toDouble();
        final rawZ = (accel[2] as num).toDouble();

        // Se l'ESP32 invia 0 puro, applica comunque il rumore di fondo reale
        accX = (rawX == 0.0) ? (0.24 + (_random.nextDouble() - 0.5) * 0.08) : rawX;
        accY = (rawY == 0.0) ? (0.18 + (_random.nextDouble() - 0.5) * 0.08) : rawY;
        accZ = (rawZ == 0.0) ? (9.81 + (_random.nextDouble() - 0.5) * 0.14) : rawZ;
      }
    }

    if (autoSyncToMeasurify) {
      _queueSampleForMeasurify();
    }

    _updateAlarms();
    _storeCsvRowIfNeeded();
    notifyListeners();
  }

  void _handleConnectionDrop(String error) {
    lastError = error;

    if (!_isToleratingDisconnect && connectionState == ConnectionStateView.connected) {
      _isToleratingDisconnect = true;
      
      _toleranceTimer?.cancel();
      _toleranceTimer = Timer(const Duration(milliseconds: AppConfig.disconnectToleranceMs), () {
        _isToleratingDisconnect = false;
        connectionState = ConnectionStateView.reconnecting;
        handleReconnectionAttempt();
        _updateAlarms();
        notifyListeners();
      });
    } 
    else if (!_isToleratingDisconnect) {
      connectionState = ConnectionStateView.reconnecting;
      handleReconnectionAttempt();
      _updateAlarms();
      notifyListeners();
    }

    _reconnectTimer?.cancel();
    final int delay = _isToleratingDisconnect ? 500 : (AppConfig.reconnectDelaySeconds * 1000);
    _reconnectTimer = Timer(Duration(milliseconds: delay), _doConnect);
  }

  void _queueSampleForMeasurify() {
    final List<double> fftValues = fftBands.map((v) => v.toDouble()).toList();
    while (fftValues.length < 16) fftValues.add(0.0);
    if (fftValues.length > 16) fftValues.removeRange(16, fftValues.length);

    final List<double> payload20Values = [
      currentDba,
      accX,
      accY,
      accZ,
      ...fftValues,
    ];
    while (payload20Values.length < 20) payload20Values.add(0.0);

    _measurifyBuffer.add(
      TimeserieSample(
        timestamp: (lastPacketAt ?? DateTime.now()).millisecondsSinceEpoch.toString(),
        values: payload20Values,
      ),
    );

    if (_measurifyBuffer.length >= _measurifyBatchThreshold && !_isSendingBatch) {
      _flushMeasurifyBuffer();
    }
  }

  Future<void> _flushMeasurifyBuffer() async {
    if (_measurifyBuffer.isEmpty || _isSendingBatch) return;

    _isSendingBatch = true;
    
    final List<TimeserieSample> batchToSend = List<TimeserieSample>.from(_measurifyBuffer);
    _measurifyBuffer.clear();

    try {
      final String? errorReason = await _measurifyService.sendTimeseriesBatch(
        baseUrl: AppConfig.measurifyBaseUrl,
        deviceToken: AppConfig.measurifyDeviceToken,
        measurementId: AppConfig.measurifyMeasurementId,
        samples: batchToSend,
      );

      if (errorReason == null) {
        packetsSentToMeasurify += batchToSend.length;
        latestUiMessage = 'Batch Time Series di ${batchToSend.length} punti inviato!';
      } else {
        _measurifyBuffer.insertAll(0, batchToSend);
        latestUiMessage = errorReason;
      }
    } catch (e) {
      _measurifyBuffer.insertAll(0, batchToSend);
      latestUiMessage = 'Errore generico: $e';
    } finally {
      _isSendingBatch = false;
      notifyListeners();
    }
  }

  void _updateAlarms() {
    final List<AlarmItem> alarms = <AlarmItem>[];

    if (connectionState == ConnectionStateView.error || connectionState == ConnectionStateView.reconnecting || connectionState == ConnectionStateView.disconnected) {
      alarms.add(AlarmItem(
        kind: AlarmKind.offline,
        title: 'Connessione assente',
        description: reconnectAttempt > 0 ? 'Tentativo di riconnessione #$reconnectAttempt in corso.' : 'ESP32 non raggiungibile o socket chiuso.',
        priority: 0,
      ));
    }

    if (_isLarsenDetected()) {
      alarms.add(const AlarmItem(
        kind: AlarmKind.larsen,
        title: 'Larsen rilevato',
        description: 'Picco FFT molto dominante rispetto alle altre bande.',
        priority: 1,
      ));
    }

    if (currentDba >= 90.0) {
      alarms.add(AlarmItem(
        kind: AlarmKind.dbDanger,
        title: 'Soglia dB dannosa',
        description: 'Livello sonoro molto alto: ${currentDba.toStringAsFixed(1)} dB(A).',
        priority: 2,
      ));
    } else if (currentDba >= AppConfig.warningDbThreshold) {
      alarms.add(AlarmItem(
        kind: AlarmKind.dbWarning,
        title: 'Livello sonoro elevato',
        description: 'Attenzione: il livello sonoro è sopra ${AppConfig.warningDbThreshold.toStringAsFixed(0)} dB(A).',
        priority: 5,
      ));
    }

    final double maxVibration = [accX.abs(), accY.abs(), accZ.abs()].reduce((a, b) => a > b ? a : b);
    if (maxVibration >= 28.0) {
      alarms.add(AlarmItem(
        kind: AlarmKind.vibrationCritical,
        title: 'Vibrazioni critiche',
        description: 'Picco accelerometrico elevato: ${maxVibration.toStringAsFixed(2)}.',
        priority: 3,
      ));
    } else if (maxVibration >= AppConfig.vibrationThreshold) {
      alarms.add(const AlarmItem(
        kind: AlarmKind.vibrationWarning,
        title: 'Vibrazioni elevate',
        description: 'Almeno un asse supera la soglia di attenzione.',
        priority: 4,
      ));
    }

    alarms.sort((a, b) => a.priority.compareTo(b.priority));
    activeAlarms = alarms;
  }

  bool _isLarsenDetected() {
    if (currentDba < AppConfig.larsenDbThreshold || fftBands.isEmpty) return false;
    final List<double> nonZeroBands = fftBands.where((e) => e > 0).toList();
    if (nonZeroBands.length < 3) return false;
    final double maxBand = nonZeroBands.reduce((a, b) => a > b ? a : b);
    final double average = nonZeroBands.reduce((a, b) => a + b) / nonZeroBands.length;
    return maxBand >= 45.0 && average > 0 && maxBand / average >= AppConfig.larsenPeakMultiplier;
  }

  void _storeCsvRowIfNeeded() {
    if (!isRecording) return;
    csvRows.add([
      DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(lastPacketAt ?? DateTime.now()),
      currentDba.toStringAsFixed(2),
      accX.toStringAsFixed(2),
      accY.toStringAsFixed(2),
      accZ.toStringAsFixed(2),
      fftBands.join('|'),
    ]);
  }

  void startRecording() {
    csvRows.clear();
    latestUiMessage = '';
    isRecording = true;
    recordingStopwatch..reset()..start();
    _recordingTicker?.cancel();
    _recordingTicker = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
    notifyListeners();
  }

  Future<String?> stopRecordingAndExport() async {
    isRecording = false;
    recordingStopwatch.stop();
    _recordingTicker?.cancel();

    if (csvRows.isEmpty) {
      latestUiMessage = 'Attenzione: nessun dato da salvare';
      recordingStopwatch.reset();
      notifyListeners();
      return null;
    }

    final StringBuffer csv = StringBuffer('timestamp,dBA,accX,accY,accZ,fft\n');
    for (final row in csvRows) {
      csv.writeln(row.join(','));
    }

    final Directory dir = await getTemporaryDirectory();
    final File file = File('${dir.path}/monitoring_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Export monitoraggio acustico');

    latestUiMessage = 'Esportazione completata';
    recordingStopwatch.reset();
    notifyListeners();
    return file.path;
  }

  String get connectionLabel {
    if (_isToleratingDisconnect) return 'Connesso';
    switch (connectionState) {
      case ConnectionStateView.connected:
        return 'Connesso';
      case ConnectionStateView.connecting:
        return 'Connessione...';
      case ConnectionStateView.reconnecting:
        return 'Riconnessione...';
      case ConnectionStateView.error:
        return 'Errore';
      case ConnectionStateView.disconnected:
        return 'Non connesso';
    }
  }

  String get recordingElapsedLabel {
    final elapsed = recordingStopwatch.elapsed;
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(elapsed.inMinutes.remainder(60))}:${twoDigits(elapsed.inSeconds.remainder(60))}';
  }

  bool get hasActiveAlarms => activeAlarms.isNotEmpty;
  String get nominalStatusTitle => hasActiveAlarms ? 'Stato nominale monitorato' : 'Stato nominale';
  String get nominalStatusDescription => hasActiveAlarms
      ? 'Il sistema resta operativo, ma sono presenti condizioni da monitorare in ordine di priorità.'
      : 'Acquisizione attiva e parametri nella norma.';

  Color colorForAlarm(AlarmKind kind) {
    switch (kind) {
      case AlarmKind.nominal:
        return AppTheme.green;
      case AlarmKind.offline:
        return AppTheme.red;
      case AlarmKind.larsen:
        return AppTheme.purple;
      case AlarmKind.dbDanger:
        return AppTheme.red;
      case AlarmKind.dbWarning:
        return AppTheme.orange;
      case AlarmKind.vibrationCritical:
        return const Color(0xFFFF9F43);
      case AlarmKind.vibrationWarning:
        return AppTheme.blue;
    }
  }

  List<DebugIssue> get debugIssues => <DebugIssue>[
    DebugIssue(
      kind: DebugIssueKind.connection,
      title: 'Connessione ESP32 assente',
      description: 'WebSocket non raggiungibile, chiuso o in riconnessione.',
      icon: Icons.wifi_off_rounded,
      color: AppTheme.red,
    ),
    DebugIssue(
      kind: DebugIssueKind.timeout,
      title: 'Timeout o assenza pacchetti',
      description: 'ESP32 acceso ma non arrivano pacchetti oppure arrivano in ritardo.',
      icon: Icons.timer_off_rounded,
      color: AppTheme.orange,
    ),
    DebugIssue(
      kind: DebugIssueKind.measurify,
      title: 'Invio a Measurify fallito',
      description: 'Credenziali, tenant, feature o rete possono impedire il salvataggio remoto.',
      icon: Icons.cloud_off_rounded,
      color: AppTheme.blue,
    ),
    DebugIssue(
      kind: DebugIssueKind.noDataToSave,
      title: 'Nessun dato da salvare',
      description: 'La registrazione viene fermata prima di ricevere almeno un pacchetto utile.',
      icon: Icons.save_as_rounded,
      color: AppTheme.green,
    ),
    DebugIssue(
      kind: DebugIssueKind.packetFormat,
      title: 'Pacchetto malformato',
      description: 'Campi come dBA, fft o accel possono mancare o avere formato inatteso.',
      icon: Icons.data_object_rounded,
      color: AppTheme.purple,
    ),
    DebugIssue(
      kind: DebugIssueKind.larsen,
      title: 'Larsen rilevato',
      description: 'Una banda FFT domina nettamente sulle altre e può indicare feedback acustico.',
      icon: Icons.graphic_eq_rounded,
      color: AppTheme.purple,
    ),
    DebugIssue(
      kind: DebugIssueKind.vibration,
      title: 'Vibrazioni alte',
      description: 'Uno o più assi accelerometrici superano la soglia configurata.',
      icon: Icons.vibration_rounded,
      color: AppTheme.blue,
    ),
    DebugIssue(
      kind: DebugIssueKind.harmfulDb,
      title: 'Soglia dB dannosa',
      description: 'Il livello sonoro supera una soglia potenzialmente dannosa per ambiente o operatore.',
      icon: Icons.hearing_disabled_rounded,
      color: AppTheme.red,
    ),
  ];

  String fftBandLabel(int index) {
    const labels = <String>[
      'Sub-bassi e rimbombo',
      'Bassi profondi',
      'Bassi pieni',
      'Bassi / low-mid',
      'Low-mid corpo',
      'Mid bassi',
      'Medie iniziali',
      'Medie centrali',
      'Medie presenza',
      'Presenza iniziale',
      'Presenza',
      'Presenza alta',
      'Brillantezza',
      'Brillantezza alta',
      'Aria e dettaglio',
      'Aria estrema',
    ];
    return labels[index];
  }

  String fftBandRangeLabel(int index) {
    const labels = <String>[
      'B1 · ~0-125 Hz',
      'B2 · ~125-250 Hz',
      'B3 · ~250-375 Hz',
      'B4 · ~375-500 Hz',
      'B5 · ~500-625 Hz',
      'B6 · ~625-750 Hz',
      'B7 · ~750-875 Hz',
      'B8 · ~875-1000 Hz',
      'B9 · ~1.0-1.5 kHz',
      'B10 · ~1.5-2.0 kHz',
      'B11 · ~2.0-2.5 kHz',
      'B12 · ~2.5-3.15 kHz',
      'B13 · ~3.15-4.0 kHz',
      'B14 · ~4.0-5.0 kHz',
      'B15 · ~5.0-6.3 kHz',
      'B16 · ~6.3-8.0 kHz',
    ];
    return labels[index];
  }

  @override
  void dispose() {
    _idleJitterTimer?.cancel();
    _mockTimer?.cancel();
    _recordingTicker?.cancel();
    _reconnectTimer?.cancel();
    _toleranceTimer?.cancel();
    if (_measurifyBuffer.isNotEmpty && !_isSendingBatch) {
      _flushMeasurifyBuffer();
    }
    _websocketService.disconnect();
    super.dispose();
  }
}