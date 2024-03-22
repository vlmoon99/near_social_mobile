import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:near_social_mobile/modules/home/pages/home_page.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';

import 'pages/post_page.dart';

class HomeModule extends Module {
  @override
  void binds(Injector i) {
    i.add(NearSocialApi.new);
    i.addSingleton(PostsController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(
      Routes.home.startPage,
      child: (context) => const HomePage(),
    );
    r.child(
      Routes.home.postPage,
      child: (context) => PostPage(
        // post: r.args.data,
        accountId: r.args.queryParams['accountId'] as String,
        blockHeight: int.parse(r.args.queryParams['blockHeight'] as String),
      ),
    );
  }
}
