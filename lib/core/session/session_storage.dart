import 'session_storage_mobile.dart'
    if (dart.library.html) 'session_storage_web.dart';

class SessionStorage {
  final _manager = SessionStorageManager();

  void saveSession(bool value) => _manager.saveSession(value);
  bool isLoggedIn() => _manager.isLoggedIn();
  void clearSession() => _manager.clearSession();
}
