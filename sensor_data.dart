class SensorData {
  final double dba;
  final List<double> fft;
  final double accX;
  final double accY;
  final double accZ;
  final DateTime timestamp;

  const SensorData({
    required this.dba,
    required this.fft,
    required this.accX,
    required this.accY,
    required this.accZ,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> accelRaw = (json['accel'] as List<dynamic>?) ?? [0, 0, 0];
    final List<dynamic> fftRaw = (json['fft'] as List<dynamic>?) ?? <dynamic>[];

    final List<double> normalizedFft = fftRaw
        .map((dynamic e) => (e as num).toDouble())
        .toList();

    return SensorData(
      dba: (json['dBA'] as num?)?.toDouble() ?? 0.0,
      fft: normalizedFft.isEmpty ? List<double>.filled(16, 0.0) : normalizedFft,
      accX: accelRaw.isNotEmpty ? (accelRaw[0] as num).toDouble() : 0.0,
      accY: accelRaw.length > 1 ? (accelRaw[1] as num).toDouble() : 0.0,
      accZ: accelRaw.length > 2 ? (accelRaw[2] as num).toDouble() : 0.0,
      timestamp: DateTime.now(),
    );
  }
}