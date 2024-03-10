import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/modules/home/pages/home_page.dart';
import 'package:near_social_mobile/routes/routes.dart';

class HomeModule extends Module {
  @override
  void routes(RouteManager r) {
    r.child(
      Routes.home.startPage,
      child: (context) => const HomePage(),
    );
  }

}
