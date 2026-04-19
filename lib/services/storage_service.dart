import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:localstorage/localstorage.dart';
import 'package:pointycastle/export.dart';

import '../core/constants/storage_keys.dart';
import '../core/session/session_storage.dart';

class StorageService {
  final LocalStorage _storage = LocalStorage('dramahub_admin');
  final SessionStorage _sessionStorage = SessionStorage();

  static const _saltPrefix = 'dramahub_';
  static const int _patExpiryDays = 10;

  Future<void> init() async {
    await _storage.ready;
  }

  Future<bool> isTokenExpired() async {
    await _storage.ready;
    final created = _storage.getItem('token_created_at');
    if (created == null) return true;
    try {
      final date = DateTime.parse(created.toString());
      return DateTime.now().difference(date).inDays >= _patExpiryDays;
    } catch (_) {
      return true;
    }
  }

  Future<bool> hasToken() async {
    await _storage.ready;
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
    await _storage.ready;
    final encrypted = _storage.getItem(StorageKeys.token);
    if (encrypted == null) return null;
    try {
      return _decrypt(encrypted.toString(), password);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearToken() async {
    await _storage.deleteItem(StorageKeys.token);
    await _storage.deleteItem('token_created_at');
  }

  Future<void> saveSession(bool isLoggedIn) async {
    _sessionStorage.saveSession(isLoggedIn);
    // On mobile, we still keep a shadow copy in localStorage if needed for specific logic,
    // but the source of truth is now the conditional sessionStorage/in-memory flag.
    if (!kIsWeb) {
      await _storage.setItem(StorageKeys.session, isLoggedIn);
    }
  }

  bool isLoggedIn() {
    return _sessionStorage.isLoggedIn();
  }

  Future<void> clearSession() async {
    _sessionStorage.clearSession();
    if (!kIsWeb) {
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
    final key = enc.Key(keyBytes);
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key));
    return encrypter.encrypt(text, iv: iv).base64;
  }

  String _decrypt(String encrypted, String password) {
    final keyBytes = _deriveKeyBytes(password, _saltPrefix);
    final key = enc.Key(keyBytes);
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key));
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
