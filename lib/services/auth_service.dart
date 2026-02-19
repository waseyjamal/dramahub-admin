import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../services/storage_service.dart';
import '../core/constants/storage_keys.dart';

class AuthService {
  final StorageService _storage;

  AuthService(this._storage);

  static const _adminPasswordHash =
      '61c3f4efd0df11769f60dfbcaf1be8ce16c022af09793b585b620782051f2ff2';

  static const int maxAttempts = 5;
  static const int lockMinutes = 15;

  bool isLocked() {
    final lockUntil = _storage.getItem(StorageKeys.lockUntil);
    if (lockUntil == null) return false;
    return DateTime.now().isBefore(DateTime.parse(lockUntil));
  }

  Future<bool> validatePassword(String password) async {
    if (isLocked()) return false;

    final hash = sha256.convert(utf8.encode(password)).toString();

    if (hash == _adminPasswordHash) {
      await _resetAttempts();
      return true;
    } else {
      await _recordFailure();
      return false;
    }
  }

  Future<void> _recordFailure() async {
    int attempts = _storage.getItem(StorageKeys.failedAttempts) ?? 0;

    attempts++;

    if (attempts >= maxAttempts) {
      final lockUntil =
          DateTime.now().add(const Duration(minutes: lockMinutes));
      await _storage.setItem(
          StorageKeys.lockUntil, lockUntil.toIso8601String());
      attempts = 0;
    }

    await _storage.setItem(StorageKeys.failedAttempts, attempts);
  }

  Future<void> _resetAttempts() async {
    await _storage.deleteItem(StorageKeys.failedAttempts);
    await _storage.deleteItem(StorageKeys.lockUntil);
  }
}
