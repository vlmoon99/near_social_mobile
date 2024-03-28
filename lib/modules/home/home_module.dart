import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/modules/core_module.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:near_social_mobile/modules/home/pages/account_info_page.dart';
import 'package:near_social_mobile/modules/home/pages/home_page.dart';
import 'package:near_social_mobile/modules/home/pages/posts_page/posts_feed_page.dart';
import 'package:near_social_mobile/modules/home/vms/posts/posts_controller.dart';
import 'package:near_social_mobile/routes/routes.dart';

import 'pages/posts_page/post_page.dart';

class HomeModule extends Module {
  
  @override
  List<Module> get imports => [
        CoreModule(),
      ];

  @override
  void binds(Injector i) {
    i.add(NearSocialApi.new);
    i.addSingleton(PostsController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child("/",
        child: (context) => const HomePage(),
        transition: TransitionType.fadeIn,
        children: [
          ChildRoute(
            Routes.home.postsFeed,
            child: (context) => const PostsFeedPage(),
          ),
          ChildRoute(
            Routes.home.accountPage,
            child: (context) => const AccountInfoPage(),
          )
        ]);
    r.child(
      Routes.home.postPage,
      child: (context) => PostPage(
        accountId: r.args.queryParams['accountId'] as String,
        blockHeight: int.parse(r.args.queryParams['blockHeight'] as String),
      ),
    );
  }
}
