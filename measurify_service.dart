import 'dart:convert';

import 'package:http/http.dart' as http;

class TimeserieSample {
  final String timestamp;
  final List<double> values;

  const TimeserieSample({
    required this.timestamp,
    required this.values,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'values': values,
      };
}

class MeasurifyService {
  static const String _tenant = 'Audio';
  static const String _thing = 'RoomA';
  static const String _feature = 'Audio_recording';
  static const String _device = 'Audio_Device';

  final http.Client _client;
  final Set<String> _createdMeasurementIds = <String>{};

  MeasurifyService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String deviceToken) => {
        'Content-Type': 'application/json',
        'Authorization': deviceToken.trim(),
        'tenant': _tenant,
      };

  Future<String?> _ensureContainerExists(
    String baseUrl,
    String deviceToken,
    String measurementId,
  ) async {
    if (_createdMeasurementIds.contains(measurementId)) return null;

    final payload = <String, dynamic>{
      '_id': measurementId,
      'thing': _thing,
      'feature': _feature,
      'device': _device,
    };

    try {
      final response = await _client
          .post(
            Uri.parse(baseUrl),
            headers: _headers(deviceToken),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200 && response.statusCode != 201) {
        return 'Creazione Measurement fallita '
            '[HTTP ${response.statusCode}]: ${response.body}';
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> ||
          decoded['_id']?.toString() != measurementId) {
        return 'Risposta creazione Measurement inattesa: ${response.body}';
      }

      _createdMeasurementIds.add(measurementId);
      print('[Measurify] Measurement pronta: $measurementId');
      return null;
    } catch (e) {
      return 'Errore durante la creazione della Measurement: $e';
    }
  }

  Future<String?> sendTimeseriesBatch({
    required String baseUrl,
    required String deviceToken,
    required String measurementId,
    required List<TimeserieSample> samples,
  }) async {
    if (samples.isEmpty) return null;

    final containerError = await _ensureContainerExists(
      baseUrl,
      deviceToken,
      measurementId,
    );
    if (containerError != null) return containerError;

    // La route confermata dal server usa "timeserie" al singolare.
    final url = Uri.parse(
      '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/'
      '${Uri.encodeComponent(measurementId)}/timeserie',
    );

    try {
      final response = await _client
          .post(
            url,
            headers: _headers(deviceToken),
            body: jsonEncode(samples.map((sample) => sample.toJson()).toList()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print(
          '[Measurify] HTTP ${response.statusCode}: '
          '${samples.length} campioni inviati a $measurementId',
        );
        return null;
      }

      final error = 'Invio timeserie fallito '
          '[HTTP ${response.statusCode}]: ${response.body}';
      print('[Measurify] $error');
      return error;
    } catch (e) {
      final error = 'Errore di rete durante l’invio timeserie: $e';
      print('[Measurify] $error');
      return error;
    }
  }

  void dispose() => _client.close();
}