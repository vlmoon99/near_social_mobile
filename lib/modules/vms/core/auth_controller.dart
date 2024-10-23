import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutterchain/flutterchain_lib/constants/core/blockchains_gas.dart';
import 'package:flutterchain/flutterchain_lib/constants/core/supported_blockchains.dart';
import 'package:flutterchain/flutterchain_lib/models/core/wallet.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'dart:typed_data';
import 'package:webcrypto/webcrypto.dart' as webcrypto;
import 'package:cloud_functions/cloud_functions.dart';

import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

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
      };

      try {
        authenticateUser(accountId, secretKey);

      } catch (e) {
        print("Error while auth uesr using firebase");
      }


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

  Future<bool> verifyTransaction({
    required String signedTx,
    required String publicKeyStr,
    required String uuid,
    required String accountId,
  }) async {
    final FirebaseFunctions functions = FirebaseFunctions.instance;

    try {
      HttpsCallable callable =
          functions.httpsCallable('verifySignedTransaction');

      final response = await callable.call(<String, dynamic>{
        'signedTx': signedTx,
        'publicKeyStr': publicKeyStr,
        'uuid': uuid,
        'accountId': accountId,
      });

      return response.data['success'] == true;
    } on FirebaseFunctionsException catch (e) {
      print('Firebase Functions Exception: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error: $e');
      return false;
    }
  }

  Future<UserCredential?> authenticateUser(
      String accountId, String secretKey) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final userCredential = await auth.signInAnonymously();

      print("secretKey  :::  " + secretKey);
      final privateKey = await nearBlockChainService
          .getPrivateKeyFromSecretKeyFromNearApiJSFormat(
        secretKey.split(":").last,
      );
      final publicKey = await nearBlockChainService
          .getPublicKeyFromSecretKeyFromNearApiJSFormat(
        secretKey.split(":").last,
      );

      final actions = [
        {
          "type": "transfer",
          "data": {"amount": "1"}
        }
      ];

      final info = await nearBlockChainService.getTransactionInfo(
          accountId: accountId, publicKey: publicKey);

      String signedTx = await nearBlockChainService.signNearActions(
        fromAddress: accountId,
        toAddress: "fake.near",
        transferAmount: "1",
        privateKey: privateKey,
        gas: BlockchainGas.gas[BlockChains.near]!,
        nonce: info.nonce,
        blockHash: info.blockHash,
        actions: actions,
      );

      print("signedTx  " + signedTx);

       verifyTransaction(
        signedTx: signedTx,
        publicKeyStr: publicKey,
        uuid: FirebaseAuth.instance.currentUser!.uid,
        accountId: accountId,
      ).then((resVerefication) async {
        final DocumentSnapshot res = await FirebaseFirestore.instance
            .collection('users')
            .doc(accountId)
            .get();


        if (res.exists) {
          print('User data: ${res.data()}');
        } else {
          print('No user found with ID: $accountId');
        }

        if (resVerefication && !res.exists) {
          final accountInfo = await NearSocialApi(
                  nearBlockChainService:
                      NearBlockChainService.defaultInstance())
              .getGeneralAccountInfo(accountId: accountId);
          print("accountInfo  " + accountInfo.toString());

          FirebaseChatCore.instance.createUserInFirestore(
            types.User(
              firstName: accountInfo.name,
              id: accountInfo.accountId,
              imageUrl: accountInfo.profileImageLink,
              lastName: "No data exist",
              role: types.Role.user,
            ),
          );
          print("resVerefication  " + resVerefication.toString());
        }
      });

      try {
        return userCredential;
      } catch (e) {
        print('Authentication error: $e');
        return null;
      }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
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
