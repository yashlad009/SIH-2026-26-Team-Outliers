import 'package:intl/intl.dart';

class DateFormatters {
  DateFormatters._();

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final _timeFormat = DateFormat('hh:mm a');
  static final _shortDate = DateFormat('dd MMM');
  static final _monthYear = DateFormat('MMM yyyy');

  static String formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return _dateFormat.format(dt);
  }

  static String formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    return _dateTimeFormat.format(dt);
  }

  static String formatTime(DateTime? dt) {
    if (dt == null) return '—';
    return _timeFormat.format(dt);
  }

  static String formatShortDate(DateTime? dt) {
    if (dt == null) return '—';
    return _shortDate.format(dt);
  }

  static String formatMonthYear(DateTime? dt) {
    if (dt == null) return '—';
    return _monthYear.format(dt);
  }

  /// Returns "Today", "Yesterday", or formatted date
  static String formatRelative(DateTime? dt) {
    if (dt == null) return '—';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return 'Today, ${formatTime(dt)}';
    if (diff == 1) return 'Yesterday, ${formatTime(dt)}';
    if (diff < 7) return '${diff}d ago';
    return formatDate(dt);
  }

  /// Returns "2 hours ago", "3 days ago", etc.
  static String timeAgo(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(dt);
  }

  /// For chart x-axis labels
  static String formatChartDate(DateTime dt) => DateFormat('dd/MM').format(dt);
}
