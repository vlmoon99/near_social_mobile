import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/services/crypto_service.dart';

class CryptoStorageService {
  final FlutterSecureStorage secureStorage;

  CryptoStorageService({required this.secureStorage});

  Future<String> read({
    required String storageKey,
  }) async {
    late String decryptedData;
    try {
      final storedDate = await secureStorage.read(key: storageKey);
      final storedEncodedKey =
          await secureStorage.read(key: SecureStorageKeys.cryptographicKey);
      if (storedDate == null || storedEncodedKey == null) {
        throw AppExceptions(
          messageForUser: "Failed to read from storage",
          messageForDev: "Failed to read from storage with key $storageKey",
          statusCode: AppErrorCodes.storageError,
        );
      }
      final cryptographicKey = CryptoUtils.keyBase64ToUint8ListKey(
        storedEncodedKey,
      );
      decryptedData = CryptoUtils.decrypt(
          cryptographicKey: cryptographicKey, data: storedDate);
    } catch (err) {
      rethrow;
    }
    return decryptedData;
  }

  Future<void> write({
    required Uint8List cryptographicKey,
    required String storageKey,
    required String data,
  }) async {
    try {
      final encodedKey = CryptoUtils.uint8ListKeyToBase64Key(cryptographicKey);
      secureStorage.write(
          key: SecureStorageKeys.cryptographicKey, value: encodedKey);
      final encryptedData =
          CryptoUtils.encrypt(cryptographicKey: cryptographicKey, data: data);
      await secureStorage.write(key: storageKey, value: encryptedData);
    } on AppExceptions catch (_) {
      rethrow;
    } catch (err) {
      throw AppExceptions(
        messageForUser: "Failed to write to storage",
        messageForDev: err.toString(),
        statusCode: AppErrorCodes.storageError,
      );
    }
  }
}
