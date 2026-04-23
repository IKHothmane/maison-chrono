void appLog(String message) {
  return;
}

String maskEmail(String email) {
  final trimmed = email.trim();
  final at = trimmed.indexOf('@');
  if (at <= 0) return trimmed.isEmpty ? '' : '${trimmed[0]}***';
  final name = trimmed.substring(0, at);
  final domain = trimmed.substring(at + 1);
  final prefix = name.isEmpty ? '*' : name[0];
  return '$prefix***@$domain';
}

String maskId(String id) {
  if (id.length <= 8) return id;
  return '${id.substring(0, 8)}…';
}
