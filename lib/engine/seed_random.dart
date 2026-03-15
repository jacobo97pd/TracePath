typedef Rng = double Function();

int _toUint32(int value) => value & 0xFFFFFFFF;

int _toSigned32(int value) {
  final v = _toUint32(value);
  return (v & 0x80000000) != 0 ? v - 0x100000000 : v;
}

int _imul32(int a, int b) {
  final aLow = a & 0xFFFF;
  final aHigh = (a >>> 16) & 0xFFFF;
  final bLow = b & 0xFFFF;
  final bHigh = (b >>> 16) & 0xFFFF;
  final low = aLow * bLow;
  final mid = ((aHigh * bLow + aLow * bHigh) & 0xFFFF) << 16;
  return _toUint32(low + mid);
}

Rng createRng(int seed) {
  var s = _toSigned32(seed);

  return () {
    s = _toSigned32(s + 0x6D2B79F5);
    var t = _imul32(s ^ (s >>> 15), 1 | s);
    t = _toUint32((t + _imul32(t ^ (t >>> 7), 61 | t)) ^ t);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296.0;
  };
}

int hashString(String str) {
  var hash = 0;
  for (final char in str.codeUnits) {
    hash = _toSigned32((hash << 5) - hash + char);
  }
  return hash.abs();
}

List<T> shuffle<T>(List<T> arr, Rng rng) {
  for (var i = arr.length - 1; i > 0; i--) {
    final j = (rng() * (i + 1)).floor();
    final temp = arr[i];
    arr[i] = arr[j];
    arr[j] = temp;
  }
  return arr;
}

int getDailySeed({DateTime? now}) {
  final date = now ?? DateTime.now();
  final dateStr = 'daily-${date.year}-${date.month}-${date.day}';
  return hashString(dateStr);
}

String getTodayString({DateTime? now}) {
  final date = now ?? DateTime.now();
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  return '${date.year}-$mm-$dd';
}
