import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart';
import '../constants/storage_keys.dart';

class SessionStorageManager {
  void saveSession(bool value) {
    try {
      web.window.sessionStorage.setItem(StorageKeys.session, value.toString());
    } catch (e) {
      if (kDebugMode) print('Error saving to sessionStorage: $e');
    }
  }

  bool isLoggedIn() {
    try {
      return web.window.sessionStorage.getItem(StorageKeys.session) == 'true';
    } catch (e) {
      if (kDebugMode) print('Error reading from sessionStorage: $e');
      return false;
    }
  }

  void clearSession() {
    try {
      web.window.sessionStorage.removeItem(StorageKeys.session);
    } catch (e) {
      if (kDebugMode) print('Error clearing sessionStorage: $e');
    }
  }
}
