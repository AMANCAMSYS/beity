class AppLogBuffer {
  static const int _maxEntries = 50;
  final List<String> _entries = [];

  void add(String entry) {
    _entries.add('${DateTime.now().toIso8601String()} $entry');
    if (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }
  }

  List<String> getRecent() => List.unmodifiable(_entries);

  void clear() => _entries.clear();
}
