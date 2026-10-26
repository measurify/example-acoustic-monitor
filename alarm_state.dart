enum AlarmLevel {
  nominal,
  warning,
  critical,
  larsen,
  vibration,
  offline,
}

class AlarmState {
  final AlarmLevel level;
  final String title;
  final String description;

  const AlarmState({
    required this.level,
    required this.title,
    required this.description,
  });

  factory AlarmState.nominal() {
    return const AlarmState(
      level: AlarmLevel.nominal,
      title: 'Sistema nominale',
      description: 'Acquisizione attiva e parametri nella norma.',
    );
  }

  factory AlarmState.warning() {
    return const AlarmState(
      level: AlarmLevel.warning,
      title: 'Livello elevato',
      description: 'Il livello sonoro richiede attenzione.',
    );
  }

  factory AlarmState.critical() {
    return const AlarmState(
      level: AlarmLevel.critical,
      title: 'Livello critico',
      description: 'La soglia sonora critica è stata superata.',
    );
  }

  factory AlarmState.larsen() {
    return const AlarmState(
      level: AlarmLevel.larsen,
      title: 'Larsen rilevato',
      description: 'È stato rilevato un picco anomalo nello spettro FFT.',
    );
  }

  factory AlarmState.vibration() {
    return const AlarmState(
      level: AlarmLevel.vibration,
      title: 'Vibrazioni eccessive',
      description: 'Almeno un asse accelerometrico supera la soglia impostata.',
    );
  }

  factory AlarmState.offline() {
    return const AlarmState(
      level: AlarmLevel.offline,
      title: 'Connessione assente',
      description: 'Tentativo automatico di riconnessione in corso.',
    );
  }
}