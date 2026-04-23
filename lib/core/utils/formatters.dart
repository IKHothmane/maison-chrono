class Formatters {
  static final _number = RegExp(r'[^0-9.,-]');

  static String formatDh(dynamic value) {
    final num? v = value is num ? value : num.tryParse(value?.toString() ?? '');
    if (v == null) return '— DH';
    final raw = v.round().toString();
    final chars = raw.split('');
    final out = <String>[];
    for (var i = 0; i < chars.length; i++) {
      final idxFromEnd = chars.length - i;
      out.add(chars[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) out.add(' ');
    }
    return '${out.join().trim()} DH';
  }

  static num? parseNum(String v) {
    final s = v.trim().replaceAll(_number, '').replaceAll(',', '.');
    if (s.isEmpty) return null;
    return num.tryParse(s);
  }
}
