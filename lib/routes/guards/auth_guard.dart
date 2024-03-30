import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/routes/routes.dart';

class AuthGuard extends RouteGuard {
  AuthGuard() : super(redirectTo: Routes.auth.getModule());
  @override
  Future<bool> canActivate(String path, ModularRoute route) async {
    final secureStorage = Modular.get<FlutterSecureStorage>();
    String? value = await secureStorage.read(key: SecureStorageKeys.authInfo);
    if (value?.isNotEmpty ?? false) {
      return Future.value(true);
    } else {
      return Future.value(false);
    }
  }
}
