import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _handshakeTimer;
  bool _connected = false;

  bool get isConnected => _connected;

  Future<void> connect({
    required String url,
    required void Function(Map<String, dynamic> data) onData,
    void Function()? onConnected,
    void Function()? onDone,
    void Function(dynamic error)? onError,
  }) async {
    await disconnect();

    try {
      final uri = Uri.parse(url);
      debugPrint('[WS] connecting to $url');
      _channel = WebSocketChannel.connect(uri);

      _handshakeTimer = Timer(const Duration(seconds: 6), () async {
        if (!_connected) {
          debugPrint('[WS] handshake timeout');
          onError?.call('Timeout handshake WebSocket');
          await disconnect();
        }
      });

      _subscription = _channel!.stream.listen(
        (dynamic message) {
          try {
            final String rawText = message.toString().trim();

            // Sblocca lo stato di connessione al primo messaggio ricevuto
            if (!_connected) {
              _connected = true;
              _handshakeTimer?.cancel();
              debugPrint('[WS] primo pacchetto ricevuto, connessione confermata');
              onConnected?.call();
            }

            // FILTRO ANTI-ERRORE: Se il messaggio non è un JSON racchiuso da graffe (es. HELLO_FROM_REAL_MIC_ESP32),
            // lo ignoriamo senza generare errori di parsing.
            if (!rawText.startsWith('{') || !rawText.endsWith('}')) {
              return;
            }

            final dynamic decoded = jsonDecode(rawText);

            if (decoded is Map<String, dynamic>) {
              onData(decoded);
            } else if (decoded is Map) {
              onData(Map<String, dynamic>.from(decoded));
            }
          } catch (e) {
            // Se un frame arriva incompleto o corrotto, non mostriamo nulla a schermo
            // per garantire stabilità visiva ed evitare pop-up rossi.
            debugPrint('[WS] Errore parsing ignorato per stabilità UI: $e');
          }
        },
        onDone: () {
          debugPrint('[WS] stream done');
          _handshakeTimer?.cancel();
          _subscription = null;
          _channel = null;
          _connected = false;
          onDone?.call();
        },
        onError: (dynamic error) {
          debugPrint('[WS] stream error: $error');
          _handshakeTimer?.cancel();
          _subscription = null;
          _channel = null;
          _connected = false;
          onError?.call(error);
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[WS] connect exception: $e');
      _handshakeTimer?.cancel();
      _subscription = null;
      _channel = null;
      _connected = false;
      onError?.call(e);
    }
  }

  Future<void> disconnect() async {
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
    _connected = false;
  }
}