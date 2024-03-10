import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/modules/auth/pages/login_page.dart';
import 'package:near_social_mobile/routes/routes.dart';

class AuthModule extends Module {
  @override
  void routes(RouteManager r) {
    r.child(
      Routes.auth.login,
      child: (context) => const LoginPage(),
    );
  }
}
