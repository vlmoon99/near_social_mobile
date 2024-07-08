import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/routes/routes.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  Future<bool> checkAuthentication() async {
    final secureStorage = Modular.get<FlutterSecureStorage>();
    String? value = await secureStorage.read(key: SecureStorageKeys.authInfo);
    if (value?.isNotEmpty ?? false) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final stopwatch = Stopwatch()..start();

      final navigateToHome = await checkAuthentication();
      stopwatch.stop();

      final remainingTime = const Duration(seconds: 2) - stopwatch.elapsed;

      if (remainingTime > Duration.zero) {
        await Future.delayed(remainingTime, () {
          if (navigateToHome) {
            Modular.to.navigate(Routes.home.getModule());
          } else {
            Modular.to.navigate(Routes.auth.getModule());
          }
        });
      } else {
        if (navigateToHome) {
          Modular.to.navigate(Routes.home.getModule());
        } else {
          Modular.to.navigate(Routes.auth.getModule());
        }
      }
    });
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/media/icons/near_social_logo.svg',
              width: 50.h,
              height: 50.h,
            ),
            SizedBox(height: 20.h),
            AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  'Near Social',
                  textStyle: const TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                  ),
                  speed: const Duration(milliseconds: 75),
                ),
              ],
              totalRepeatCount: 1,
            ),
          ],
        ),
      ),
    );
  }
}
