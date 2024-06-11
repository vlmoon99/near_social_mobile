import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/core_module.dart';
import 'package:near_social_mobile/modules/splash_page.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';

import 'auth/auth_module.dart';
import 'home/home_module.dart';

class AppModule extends Module {
  @override
  List<Module> get imports => [
        CoreModule(),
      ];

  @override
  void binds(Injector i) {
    i.addSingleton(Catcher.new);
    i.addSingleton(AuthController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(
      "/",
      child: (context) => const SplashPage(),
    );
    r.module(
      Routes.auth.module,
      module: AuthModule(),
    );
    r.module(
      Routes.home.module,
      module: HomeModule(),
    );
  }
}
