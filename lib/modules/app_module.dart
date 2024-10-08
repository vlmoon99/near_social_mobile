import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/core_module.dart';
import 'package:near_social_mobile/modules/auth/pages/start_page/start_splash_page.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/routes/guards/auth_guard.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/services/notification_subscription_service.dart';

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
    i.addSingleton(NotificationSubscriptionService.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(
      "/",
      child: (context) => const StartSplashPage(),
    );
    r.module(
      Routes.auth.module,
      module: AuthModule(),
    );
    r.module(
      Routes.home.module,
      module: HomeModule(),
      guards: [AuthGuard()],
    );
  }
}
