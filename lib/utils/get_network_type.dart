import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:near_social_mobile/config/constants.dart';

enum NearNetworkType { testnet, mainnet }

Future<NearNetworkType> getNearNetworkType() async {
  final secureStorage = Modular.get<FlutterSecureStorage>();
  final networkType = await secureStorage.read(key: StorageKeys.networkType);
  if (networkType == "mainnet") {
    return NearNetworkType.mainnet;
  } else {
    return NearNetworkType.testnet;
  }
}
