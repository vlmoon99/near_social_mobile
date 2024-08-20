import 'dart:convert';

import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutterchain/flutterchain_lib/models/chains/near/near_blockchain_data.dart';
import 'package:flutterchain/flutterchain_lib/models/core/wallet.dart';
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

  Stream<AuthInfo> get stream => _streamController.stream;

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

      final secretKeyInNearApiJsFormat =
          await nearBlockChainService.exportPrivateKeyToTheNearApiJsFormat(
        currentBlockchainData: NearBlockChainData(
          publicKey: publicKey,
          privateKey: secretKey,
          passphrase: "",
          derivationPath: const DerivationPath(
            purpose: '',
            coinType: '',
            accountNumber: '',
            change: '',
            address: '',
          ),
        ),
      );

      final additionalStoredKeys = {
        "Near Social QR Functional Key": PrivateKeyInfo(
          publicKey: accountId,
          privateKey: secretKey,
          privateKeyInNearApiJsFormat: secretKeyInNearApiJsFormat,
          privateKeyTypeInfo: PrivateKeyTypeInfo(
            type: PrivateKeyType.FunctionCall,
            receiverId: "social.near",
            methodNames: [],
          ),
        ),
        ...await _getAdditionalAccessKeys()
      }; // ;

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

  Future<void> logout() async {
    try {
      await secureStorage.delete(key: SecureStorageKeys.authInfo);
      await secureStorage.delete(
          key: SecureStorageKeys.additionalCryptographicKeys);
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
        additionalStoredKeys: state.additionalStoredKeys
          ..putIfAbsent(accessKeyName, () => privateKeyInfo),
      );
      await cryptoStorageService.write(
        storageKey: SecureStorageKeys.additionalCryptographicKeys,
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
        additionalStoredKeys: state.additionalStoredKeys..remove(accessKeyName),
      );
      await cryptoStorageService.write(
        storageKey: SecureStorageKeys.additionalCryptographicKeys,
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
        storageKey: SecureStorageKeys.additionalCryptographicKeys,
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
