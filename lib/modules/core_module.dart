import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutterchain/flutterchain_lib/constants/chains/near_blockchain_network_urls.dart';
import 'package:flutterchain/flutterchain_lib/network/chains/near_rpc_client.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:flutterchain/flutterchain_lib/services/core/js_engines/platforms_implementations/webview_js_engine.dart';
import 'package:near_social_mobile/services/dio_interceptors/retry_with_change_base_url.dart';

class CoreModule extends Module {
  @override
  void exportedBinds(i) {
    i.addInstance<FlutterSecureStorage>(const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    ));
    i.addInstance<NearBlockChainService>(
      NearBlockChainService(
        jsVMService: getJsVM(),
        nearRpcClient: NearRpcClient(
          networkClient: CustomNearNetworkClient(
            baseUrl: NearUrls.blockchainRpc,
            dio: Dio(),
          ),
        ),
      ),
    );
  }
}

class CustomNearNetworkClient extends NearNetworkClient {
  CustomNearNetworkClient({required super.baseUrl, required super.dio}) {
    dio.interceptors.clear();
    dio.interceptors.addAll(
      [
        RetryInterceptorWithSecondaryLink(
          dio: dio,
          retries: 8,
          logPrint: log,
          retryDelays: [const Duration(seconds: 1)],
          primaryLink: NearUrls.blockchainRpc,
          secondaryLink: NearBlockChainNetworkUrls.listOfUrls.elementAt(1),
        )
      ],
    );
  }
}
