/// Short remaining-time label for boss cards and lists.
String bossTimeLeft(DateTime deadline, DateTime now) {
  final diff = deadline.difference(now);
  if (diff.isNegative) return 'Overdue';
  if (diff.inDays >= 1) return '${diff.inDays}d left';
  if (diff.inHours >= 1) return '${diff.inHours}h left';
  return '${diff.inMinutes}m left';
}

String bossStatusLabel(String status) {
  if (status.isEmpty) return status;
  return status[0].toUpperCase() + status.substring(1);
}
