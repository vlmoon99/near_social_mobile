import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/apis/models/private_key_info.dart';
import 'package:near_social_mobile/services/crypto_storage_service.dart';
import 'package:rxdart/rxdart.dart';

import 'models/auth_info.dart';

class AuthController extends Disposable {
  final NearBlockChainService nearBlockChainService;
  final FlutterSecureStorage secureStorage;
  late final CryptoStorageService cryptoStorageService;

  final BehaviorSubject<AuthInfo> _streamController =
      BehaviorSubject.seeded(const AuthInfo());

  AuthController(this.nearBlockChainService, this.secureStorage)
      : cryptoStorageService =
            CryptoStorageService(secureStorage: secureStorage);

  Stream<AuthInfo> get stream => _streamController.stream.distinct();

  AuthInfo get state => _streamController.value;

  Future<void> login({
    required String accountId,
    required String secretKey,
  }) async {
    try {
      _streamController.add(state.copyWith(
        accountId: accountId,
        secretKey: secretKey,
      ));

      final privateKey = await nearBlockChainService
          .getPrivateKeyFromSecretKeyFromNearApiJSFormat(
        secretKey.split(":").last,
      );
      final publicKey = await nearBlockChainService
          .getPublicKeyFromSecretKeyFromNearApiJSFormat(
        secretKey.split(":").last,
      );

      final base58PubKey = await nearBlockChainService
          .getBase58PubKeyFromHexValue(hexEncodedPubKey: publicKey);

      final additionalStoredKeys = {
        "Near Social QR Functional Key": PrivateKeyInfo(
          publicKey: accountId,
          privateKey: secretKey,
          base58PubKey: base58PubKey,
          privateKeyTypeInfo: const PrivateKeyTypeInfo(
            type: PrivateKeyType.FunctionCall,
            receiverId: "social.near",
            methodNames: [],
          ),
        ),
        ...await _getAdditionalAccessKeys()
      }; // ;


      await authenticateUser(accountId, secretKey);
      
      _streamController.add(state.copyWith(
        accountId: accountId,
        publicKey: publicKey,
        secretKey: secretKey,
        privateKey: privateKey,
        additionalStoredKeys: additionalStoredKeys,
        status: AuthInfoStatus.authenticated,
      ));
    } catch (err) {
      rethrow;
    }
  }

  Future<UserCredential?> authenticateUser(
      String accountId, String secretKey) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var bytes = utf8.encode(secretKey);
    secretKey = sha256.convert(bytes).toString();
    try {
        final userCredential = await _auth.signInAnonymously();
        return userCredential;
    } catch (e) {
      print('Authentication error: $e');
      return null;
    }
  }
  Future<void> logout() async {
    try {
      await secureStorage.delete(key: StorageKeys.authInfo);
      await secureStorage.delete(key: StorageKeys.additionalCryptographicKeys);
      _streamController.add(const AuthInfo());
    } catch (err) {
      throw AppExceptions(
        messageForUser: "Failed to logout",
        messageForDev: err.toString(),
      );
    }
  }

  Future<void> addAccessKey({
    required String accessKeyName,
    required PrivateKeyInfo privateKeyInfo,
  }) async {
    try {
      final newState = state.copyWith(
        additionalStoredKeys: Map.of(state.additionalStoredKeys)
          ..putIfAbsent(accessKeyName, () => privateKeyInfo),
      );
      await cryptoStorageService.write(
        storageKey: StorageKeys.additionalCryptographicKeys,
        data: jsonEncode(newState.additionalStoredKeys),
      );
      _streamController.add(newState);
    } catch (err) {
      final appException = AppExceptions(
        messageForUser: "Failed to add key",
        messageForDev: err.toString(),
      );

      throw appException;
    }
  }

  Future<void> removeAccessKey({required String accessKeyName}) async {
    try {
      final newState = state.copyWith(
        additionalStoredKeys: Map.of(state.additionalStoredKeys)
          ..remove(accessKeyName),
      );
      await cryptoStorageService.write(
        storageKey: StorageKeys.additionalCryptographicKeys,
        data: jsonEncode(newState.additionalStoredKeys),
      );
      _streamController.add(newState);
    } catch (err) {
      final appException = AppExceptions(
        messageForUser: "Failed to remove key",
        messageForDev: err.toString(),
      );
      throw appException;
    }
  }

  Future<Map<String, PrivateKeyInfo>> _getAdditionalAccessKeys() async {
    try {
      final encodedData = await cryptoStorageService.read(
        storageKey: StorageKeys.additionalCryptographicKeys,
      );
      final decodedData = jsonDecode(encodedData) as Map<String, dynamic>?;
      if (decodedData == null) {
        return {};
      }
      final additionalKeys = decodedData.map((key, value) {
        return MapEntry(key, PrivateKeyInfo.fromJson(value));
      });
      return additionalKeys;
    } catch (err) {
      return {};
    }
  }

  @override
  void dispose() {
    _streamController.close();
  }
}
