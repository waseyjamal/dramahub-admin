import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:localstorage/localstorage.dart';
import 'package:pointycastle/export.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html if (dart.library.io) '../core/stubs/html_stub.dart';

import '../core/constants/storage_keys.dart';

class StorageService {
  final LocalStorage _storage = LocalStorage('dramahub_admin');

  static const _saltPrefix = 'dramahub_';
  static const int _patExpiryDays = 10;

  bool isTokenExpired() {
    final created = _storage.getItem('token_created_at');
    if (created == null) return true;
    try {
      final date = DateTime.parse(created);
      return DateTime.now().difference(date).inDays >= _patExpiryDays;
    } catch (_) {
      return true;
    }
  }

  bool hasToken() {
    final token = _storage.getItem(StorageKeys.token);
    return token != null && token.toString().isNotEmpty;
  }

  Future<void> saveToken(String token, String password) async {
    final encrypted = _encrypt(token, password);
    await _storage.setItem(StorageKeys.token, encrypted);
    await _storage.setItem(
      'token_created_at',
      DateTime.now().toIso8601String(),
    );
  }

  Future<String?> getToken(String password) async {
    final encrypted = _storage.getItem(StorageKeys.token);
    if (encrypted == null) return null;
    try {
      return _decrypt(encrypted, password);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearToken() async {
    await _storage.deleteItem(StorageKeys.token);
    await _storage.deleteItem('token_created_at');
  }

  Future<void> saveSession(bool isLoggedIn) async {
    if (kIsWeb) {
      html.window.sessionStorage[StorageKeys.session] = isLoggedIn.toString();
    } else {
      await _storage.setItem(StorageKeys.session, isLoggedIn);
    }
  }

  bool isLoggedIn() {
    if (kIsWeb) {
      return html.window.sessionStorage[StorageKeys.session] == 'true';
    }
    return _storage.getItem(StorageKeys.session) ?? false;
  }

  Future<void> clearSession() async {
    if (kIsWeb) {
      html.window.sessionStorage.remove(StorageKeys.session);
    } else {
      await _storage.deleteItem(StorageKeys.session);
    }
  }

  // --- Android Lifecycle Safety Net ---
  Future<void> savePauseTimestamp() async {
    if (!kIsWeb) {
      await _storage.setItem(
          'last_paused_timestamp', DateTime.now().toIso8601String());
    }
  }

  String? getPauseTimestamp() {
    return _storage.getItem('last_paused_timestamp');
  }

  Future<void> clearPauseTimestamp() async {
    await _storage.deleteItem('last_paused_timestamp');
  }

  String? getTokenCreatedAt() {
    return _storage.getItem('token_created_at');
  }

  dynamic getItem(String key) {
    return _storage.getItem(key);
  }

  Future<void> setItem(String key, dynamic value) async {
    await _storage.setItem(key, value);
  }

  Future<void> deleteItem(String key) async {
    await _storage.deleteItem(key);
  }

  String _encrypt(String text, String password) {
    final keyBytes = _deriveKeyBytes(password, _saltPrefix);
    final key = Key(keyBytes);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    return encrypter.encrypt(text, iv: iv).base64;
  }

  String _decrypt(String encrypted, String password) {
    final keyBytes = _deriveKeyBytes(password, _saltPrefix);
    final key = Key(keyBytes);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    return encrypter.decrypt64(encrypted, iv: iv);
  }

  Uint8List _deriveKeyBytes(String password, String salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(
      Pbkdf2Parameters(
        Uint8List.fromList(utf8.encode(salt)),
        100000,
        32,
      ),
    );
    return pbkdf2.process(
      Uint8List.fromList(utf8.encode(password)),
    );
  }
}
