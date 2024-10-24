import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutterchain/flutterchain_lib/constants/core/supported_blockchains.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:flutterchain/flutterchain_lib/services/core/crypto_service.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/network/dio_interceptors/retry_on_connection_changed_interceptor.dart';

class TestNetService {
  final FlutterChainService flutterChainService =
      FlutterChainService.defaultInstance();

  Future<({String publicKey, String secretKey})> createAccount() async {
    try {
      final nearBlockChainService = flutterChainService
          .blockchainServices[BlockChains.near] as NearBlockChainService;

      final wallet = await flutterChainService.generateNewWallet(
          walletName: "GeneratedRandom ${DateTime.now()}", passphrase: '');

      final blockchainData = await nearBlockChainService.getBlockChainData(
          mnemonic: wallet.mnemonic, passphrase: wallet.passphrase);

      final secretKey =
          await nearBlockChainService.exportPrivateKeyToTheNearApiJsFormat(
        currentBlockchainData: blockchainData,
      );

      log("TestNet account public key: ${blockchainData.publicKey}");
      log("TestNet account private key: ${blockchainData.privateKey}");
      log("TestNet account secret key: $secretKey");

      final Dio dio = Dio();
      dio.interceptors.addAll([
        RetryInterceptor(
          dio: dio,
          logPrint: log,
          retries: 5,
          retryDelays: [
            ...List.generate(5, (index) => const Duration(seconds: 1))
          ],
        ),
        RetryOnConnectionChangeInterceptor(
          dio: dio,
          connectivity: Connectivity(),
        ),
      ]);

      final response = await dio.post(
        "https://server-for-account-creation.onrender.com/create-account",
        data: {
          "accountId": blockchainData.publicKey,
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
      );

      if (!(response.data["message"] as String)
          .contains("Account created and funded")) {
        throw Exception(response.data.toString());
      }
      return (
        publicKey: blockchainData.publicKey,
        secretKey: secretKey,
      );
    } catch (err) {
      throw AppExceptions(
        messageForUser: "Failed to create account",
        messageForDev: err.toString(),
      );
    }
  }
}
