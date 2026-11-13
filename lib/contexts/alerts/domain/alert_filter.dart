import 'client_alert.dart';

/// Ventana de tiempo del historial.
enum AlertPeriod {
  all(null),
  today(Duration(days: 1)),
  week(Duration(days: 7)),
  month(Duration(days: 30));

  const AlertPeriod(this.window);

  final Duration? window;
}

/// Filtro del historial por fecha, nivel y sensor.
class AlertFilter {
  const AlertFilter({
    this.period = AlertPeriod.all,
    this.level,
    this.deviceId,
  });

  final AlertPeriod period;

  /// safe | caution | danger; null = todos.
  final String? level;

  /// null = todos los sensores.
  final int? deviceId;

  bool get isActive =>
      period != AlertPeriod.all || level != null || deviceId != null;

  AlertFilter copyWith({
    AlertPeriod? period,
    String? Function()? level,
    int? Function()? deviceId,
  }) =>
      AlertFilter(
        period: period ?? this.period,
        level: level != null ? level() : this.level,
        deviceId: deviceId != null ? deviceId() : this.deviceId,
      );

  List<ClientAlert> apply(List<ClientAlert> alerts, {DateTime? now}) {
    final window = period.window;
    final since = window == null ? null : (now ?? DateTime.now()).subtract(window);
    return alerts.where((a) {
      if (level != null && a.level != level) return false;
      if (deviceId != null && a.deviceId != deviceId) return false;
      if (since != null) {
        final at = DateTime.tryParse(a.recordedAt ?? '');
        // Sin marca de tiempo no se puede ubicar en la ventana.
        if (at == null || at.isBefore(since)) return false;
      }
      return true;
    }).toList();
  }

  /// Sensores presentes en el historial, para elegir uno.
  static Map<int, String> devicesIn(List<ClientAlert> alerts) => {
        for (final a in alerts)
          if (a.deviceId != null) a.deviceId!: a.deviceName ?? '#${a.deviceId}',
      };
}
