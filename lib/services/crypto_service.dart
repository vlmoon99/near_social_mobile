import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';

class CryptoUtils {
  static Uint8List generateCryptographicKey([int keyLength = 32]) {
    late Uint8List key;
    try {
      final random = Random.secure();
      key = Uint8List(keyLength);
      for (int i = 0; i < key.length; i++) {
        key[i] = random.nextInt(256);
      }
    } catch (err) {
      throw AppExceptions(
        messageForUser: "Failed to generate cryptographic key",
        messageForDev: err.toString(),
      );
    }
    return key;
  }

  static Uint8List keyBase64ToUint8ListKey(String keyBase64) {
    late Uint8List key;
    try {
      key = Uint8List.fromList(base64.decode(keyBase64));
    } catch (err) {
      throw AppExceptions(
        messageForUser: "Failed to decode cryptographic key",
        messageForDev: err.toString(),
      );
    }
    return key;
  }

  static String uint8ListKeyToBase64Key(Uint8List key) {
    late String base64Key;
    try {
      base64Key = base64.encode(key);
    } catch (err) {
      throw AppExceptions(
        messageForUser: "Failed to encode cryptographic key",
        messageForDev: err.toString(),
      );
    }
    return base64Key;
  }

  static String decrypt(
      {required Uint8List cryptographicKey, required String data}) {
    late String decryptedData;
    try {
      final key = Key(cryptographicKey);
      final iv = IV.fromUtf8(
        key.base16.substring(0, 16),
      );
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      final encrypted = Encrypted.fromBase64(data);
      decryptedData = encrypter.decrypt(encrypted, iv: iv);
    } catch (err) {
      throw AppExceptions(
        messageForUser: "Failed to decrypt data",
        messageForDev: err.toString(),
      );
    }
    return decryptedData;
  }

  static String encrypt(
      {required Uint8List cryptographicKey, required String data}) {
    late String encryptedData;
    try {
      final key = Key(cryptographicKey);
      final iv = IV.fromUtf8(
        key.base16.substring(0, 16),
      );
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      encryptedData = encrypter.encrypt(data, iv: iv).base64;
    } catch (err) {
      throw AppExceptions(
        messageForUser: "Failed to encrypt data",
        messageForDev: err.toString(),
      );
    }
    return encryptedData;
  }
}