import 'dart:html' as html;
import '../constants/storage_keys.dart';

class SessionStorageManager {
  void saveSession(bool value) {
    html.window.sessionStorage[StorageKeys.session] = value.toString();
  }

  bool isLoggedIn() {
    return html.window.sessionStorage[StorageKeys.session] == 'true';
  }

  void clearSession() {
    html.window.sessionStorage.remove(StorageKeys.session);
  }
}
