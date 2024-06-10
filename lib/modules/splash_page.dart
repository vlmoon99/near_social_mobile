import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:near_social_mobile/routes/routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Modular.to.navigate(Routes.home.getModule());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/media/icons/near_social_logo.svg',
              width: 50.w,
              height: 50.w,
            ),
            SizedBox(height: 20.w),
            AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  'Near Social',
                  textStyle: TextStyle(
                    fontSize: 32.0.sp,
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
