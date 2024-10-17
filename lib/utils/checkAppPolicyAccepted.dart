import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:near_social_mobile/config/constants.dart';

Future<bool> checkAppPolicyAccepted() async {
  final secureStorage = Modular.get<FlutterSecureStorage>();
  String? value = await secureStorage.read(key: StorageKeys.appPolicyAccepted);
  if (value?.isNotEmpty ?? false) {
    return true;
  } else {
    return false;
  }
}
