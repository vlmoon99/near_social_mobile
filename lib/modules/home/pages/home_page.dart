import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/config/theme.dart';
import 'package:near_social_mobile/modules/vms/core/auth_controller.dart';
import 'package:near_social_mobile/modules/vms/core/models/auth_info.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/services/firebase/firebase_notifications.dart';
import 'package:near_social_mobile/utils/check_for_jailbreak.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    Modular.to.navigate(".${Routes.home.postsFeed}");
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    checkForJailbreak();
  }

  int currentIndex(String currentRoute) {
    if (currentRoute.contains(Routes.home.postsFeed)) {
      return 0;
    } else if (currentRoute.contains(Routes.home.widgetsListPage)) {
      return 1;
    } else if (currentRoute.contains(Routes.home.peopleListPage)) {
      return 2;
    } else if (currentRoute.contains(Routes.home.notificationsPage)) {
      return 3;
    } else if (currentRoute.contains(Routes.home.homeMenu)) {
      return 4;
    } else {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Modular.get<AuthController>();
    return StreamBuilder<AuthInfo>(
      stream: authController.stream,
      builder: (context, _) {
        if (authController.state.status == AuthInfoStatus.authenticated) {
          FirebaseNotificationService.subscribeToNotifications(
              authController.state.accountId);
        }
        return Scaffold(
          appBar: AppBar(
            title: SvgPicture.asset(NearAssets.logoIcon),
            centerTitle: true,
          ),
          body: const RouterOutlet(),
          bottomNavigationBar: NavigationListener(builder: (_, __) {
            return BottomNavigationBar(
              backgroundColor: NEARColors.black,
              selectedItemColor: Theme.of(context).primaryColor,
              unselectedItemColor: NEARColors.white,
              type: BottomNavigationBarType.fixed,
              currentIndex: currentIndex(Modular.to.path),
              items: const [
                BottomNavigationBarItem(
                  backgroundColor: NEARColors.black,
                  icon: Icon(Icons.feed),
                  label: "Feed",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.widgets),
                  label: "Widgets",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: "Users",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications),
                  label: "Alerts",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu),
                  label: "Menu",
                ),
              ],
              onTap: (value) {
                switch (value) {
                  case 0:
                    Modular.to.navigate(".${Routes.home.postsFeed}");
                    break;
                  case 1:
                    Modular.to.navigate(".${Routes.home.widgetsListPage}");
                    break;
                  case 2:
                    Modular.to.navigate(".${Routes.home.peopleListPage}");
                    break;
                  case 3:
                    Modular.to.navigate(".${Routes.home.notificationsPage}");
                    break;
                  case 4:
                    Modular.to.navigate(".${Routes.home.homeMenu}");
                    break;
                  default:
                    Modular.to.navigate(".${Routes.home.postsFeed}");
                    break;
                }
              },
            );
          }),
        );
      },
    );
  }
}
