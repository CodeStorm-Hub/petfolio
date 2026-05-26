class DateParser {
  static String formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';
  }

  static String formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final hr12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hr12:${minute.toString().padLeft(2, '0')} $ampm';
  }
}
