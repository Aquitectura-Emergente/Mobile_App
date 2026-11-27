import 'app_i18n.dart';

/// Formatos de fecha, hora y cifras de la app (sin dependencias externas).
abstract final class EmsFormat {
  static bool get _es => I18n.lang.value == 'es';

  static const _monthsEs = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
  static const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _daysEs = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  static const _daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _daysLongEs = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  static const _daysLongEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static String month(int m) => (_es ? _monthsEs : _monthsEn)[m - 1];
  static String weekday(DateTime d) => (_es ? _daysEs : _daysEn)[d.weekday - 1];

  /// 14:37
  static String time(DateTime d) => '${_pad(d.hour)}:${_pad(d.minute)}';

  /// 14:37:05
  static String timeSec(DateTime d) => '${time(d)}:${_pad(d.second)}';

  /// 26 nov 2026 · Nov 26, 2026
  static String date(DateTime d) => _es ? '${d.day} ${month(d.month)} ${d.year}' : '${month(d.month)} ${d.day}, ${d.year}';

  /// 26 nov · Nov 26
  static String dayMonth(DateTime d) => _es ? '${d.day} ${month(d.month)}' : '${month(d.month)} ${d.day}';

  /// 26 nov 2026, 14:37
  static String dateTime(DateTime d) => '${date(d)}, ${time(d)}';

  /// mié 25
  static String shortDay(DateTime d) => '${weekday(d)} ${d.day}';

  /// Hoy · Ayer · Miércoles 25 nov
  static String dayTitle(DateTime day, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final d = DateTime(day.year, day.month, day.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return tr('m_today');
    if (diff == 1) return tr('m_yesterday');
    final long = (_es ? _daysLongEs : _daysLongEn)[d.weekday - 1];
    return '$long ${dayMonth(d)}${d.year != n.year ? ' ${d.year}' : ''}';
  }

  /// 2 h 15 min · 45 s
  static String duration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds} s';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 48) {
      final m = d.inMinutes % 60;
      return m == 0 ? '${d.inHours} h' : '${d.inHours} h $m min';
    }
    return '${d.inDays} d';
  }

  /// Valor con decimales fijos; "—" si falta.
  static String value(double? v, {int decimals = 1}) => v == null ? '—' : v.toStringAsFixed(decimals);

  /// Rango horario de un tramo: 14:00–15:00
  static String span(DateTime from, DateTime to) => '${time(from)}–${time(to)}';
}
