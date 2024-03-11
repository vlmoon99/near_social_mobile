import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:rxdart/rxdart.dart';

import 'models/auth_info.dart';

class AuthController extends Disposable {
  final NearBlockChainService nearBlockChainService;
  final FlutterSecureStorage secureStorage;

  final BehaviorSubject<AuthInfo> _streamController =
      BehaviorSubject.seeded(const AuthInfo());

  AuthController(this.nearBlockChainService, this.secureStorage);

  Stream<AuthInfo> get stream => _streamController.stream;

  AuthInfo get state => _streamController.value;

  Future<void> login({
    required String accountId,
    required String secretKey,
  }) async {
    // TODO: check validation of account
    // final balance = await nearBlockChainService.getWalletBalance(accountId);

    final privateKey = await nearBlockChainService
        .getPrivateKeyFromSecretKeyFromNearApiJSFormat(
      secretKey.split(":").last,
    );
    final publicKey = await nearBlockChainService
        .getPublicKeyFromSecretKeyFromNearApiJSFormat(
      secretKey.split(":").last,
    );
    
    _streamController.add(state.copyWith(
      accountId: accountId,
      publicKey: publicKey,
      secretKey: secretKey,
      privateKey: privateKey,
      status: AuthInfoStatus.authenticated,
    ));
  }

  @override
  void dispose() {
    _streamController.close();
  }
}
