import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../constants/storage_keys.dart';

class SessionStorageManager {
  void saveSession(bool value) {
    try {
      final storage = html.window.sessionStorage;
      storage[StorageKeys.session] = value.toString();
    } catch (e) {
      if (kDebugMode) print('Error saving to sessionStorage: $e');
    }
  }

  bool isLoggedIn() {
    try {
      final storage = html.window.sessionStorage;
      return storage[StorageKeys.session] == 'true';
    } catch (e) {
      if (kDebugMode) print('Error reading from sessionStorage: $e');
      return false;
    }
  }

  void clearSession() {
    try {
      final storage = html.window.sessionStorage;
      storage.remove(StorageKeys.session);
    } catch (e) {
      if (kDebugMode) print('Error clearing sessionStorage: $e');
    }
  }
}
