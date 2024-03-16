import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutterchain/flutterchain_lib/constants/chains/near_blockchain_network_urls.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/guards/auth_guard.dart';
import 'package:near_social_mobile/routes/routes.dart';

import 'auth/auth_module.dart';
import 'home/home_module.dart';

class AppModule extends Module {
  @override
  void binds(Injector i) {
    i.addInstance<FlutterSecureStorage>(const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    ));
    i.addSingleton(Catcher.new);


    i.addInstance<NearBlockChainService>(
      NearBlockChainService.defaultInstance()
        ..setBlockchainNetworkEnvironment(
          newUrl: NearBlockChainNetworkUrls.listOfUrls.elementAt(1),
        ),
    );

    i.addSingleton(AuthController.new);
  }

  @override
  void routes(RouteManager r) {
    r.module(
      Routes.auth.module,
      module: AuthModule(),
    );
    r.module(
      Routes.home.module,
      module: HomeModule(),
      guards: [
        AuthGuard(),
      ],
    );
  }
}
