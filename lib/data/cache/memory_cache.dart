class CacheEntry {
  final dynamic data;
  final DateTime expiry;

  CacheEntry(this.data, this.expiry);

  bool get isExpired => DateTime.now().isAfter(expiry);
}

class MemoryCache {
  final Map<String, CacheEntry> _store = {};

  void set(String key, dynamic data, Duration duration) {
    _store[key] = CacheEntry(data, DateTime.now().add(duration));
  }

  dynamic get(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _store.remove(key);
      return null;
    }
    return entry.data;
  }

  void invalidate(String key) {
    _store.remove(key);
  }

  void clear() {
    _store.clear();
  }
}
