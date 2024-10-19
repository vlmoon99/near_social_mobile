import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/services/crypto_service.dart';

class CryptoStorageService {
  final FlutterSecureStorage secureStorage;

  CryptoStorageService({required this.secureStorage});

  Future<String> read({
    required String storageKey,
  }) async {
    late String decryptedData;
    try {
      final storedData = await secureStorage.read(key: storageKey);
      final storedEncodedKey =
          await secureStorage.read(key: StorageKeys.cryptographicKey);
      if (storedData == null || storedEncodedKey == null) {
        throw Exception(
            "Failed to read data from storage: $storedEncodedKey $storedData");
      }
      final cryptographicKey = CryptoUtils.keyBase64ToUint8ListKey(
        storedEncodedKey,
      );
      decryptedData = CryptoUtils.decrypt(
          cryptographicKey: cryptographicKey, data: storedData);
    } catch (err) {
      rethrow;
    }
    return decryptedData;
  }

  Future<void> write({
    required String storageKey,
    required String data,
  }) async {
    try {
      final storedEncodedKey =
          await secureStorage.read(key: StorageKeys.cryptographicKey);
      if (storedEncodedKey == null) {
        throw Exception("Failed to read crypto key from storage");
      }
      final cryptographicKey = CryptoUtils.keyBase64ToUint8ListKey(
        storedEncodedKey,
      );
      final encryptedData =
          CryptoUtils.encrypt(cryptographicKey: cryptographicKey, data: data);
      await secureStorage.write(key: storageKey, value: encryptedData);
    } catch (err) {
      rethrow;
    }
  }

  Future<void> saveCryptographicKeyToStorage({
    required Uint8List cryptographicKey,
  }) async {
    final encodedKey = CryptoUtils.uint8ListKeyToBase64Key(cryptographicKey);
    await secureStorage.write(
      key: StorageKeys.cryptographicKey,
      value: encodedKey,
    );
  }
}
