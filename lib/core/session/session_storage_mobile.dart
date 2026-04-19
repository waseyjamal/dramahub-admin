class SessionStorageManager {
  static bool _session = false;

  void saveSession(bool value) {
    _session = value;
  }

  bool isLoggedIn() {
    return _session;
  }

  void clearSession() {
    _session = false;
  }
}
