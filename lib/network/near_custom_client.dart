import 'dart:developer';

import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutterchain/flutterchain_lib/constants/chains/near_blockchain_network_urls.dart';
import 'package:flutterchain/flutterchain_lib/network/chains/near_rpc_client.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/network/dio_interceptors/retry_with_change_base_url.dart';

class CustomNearNetworkClient extends NearNetworkClient {
  CustomNearNetworkClient({required super.baseUrl, required super.dio}) {
    super.dio.interceptors.removeWhere((element) => element is RetryInterceptor);
    super.dio.interceptors.addAll(
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
