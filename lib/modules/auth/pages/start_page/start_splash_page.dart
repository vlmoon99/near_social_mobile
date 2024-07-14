import 'dart:math';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/config/theme.dart';
import 'package:near_social_mobile/modules/auth/pages/start_page/widgets/auth_body.dart';
import 'package:near_social_mobile/modules/auth/pages/start_page/widgets/login_body.dart';

class StartSplashPage extends StatefulWidget {
  const StartSplashPage({super.key});

  @override
  State<StartSplashPage> createState() => _StartSplashPageState();
}

class _StartSplashPageState extends State<StartSplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  final ValueNotifier<bool?> localyAuthenticated = ValueNotifier(false);

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
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.25),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) async {
        final stopwatch = Stopwatch()..start();

        final checkedAuthentication = await checkAuthentication();
        stopwatch.stop();

        final remainingTime =
            const Duration(milliseconds: 1300) - stopwatch.elapsed;

        if (remainingTime > Duration.zero) {
          await Future.delayed(remainingTime, () {
            localyAuthenticated.value = checkedAuthentication;
          });
        } else {
          localyAuthenticated.value = checkedAuthentication;
        }
        _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const StarryBackground(),
            Positioned(
              top: 0.4.sh,
              child: SlideTransition(
                position: _offsetAnimation,
                child: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/media/icons/near_social_logo.svg',
                      width: 40.h,
                      height: 40.h,
                    ),
                    SizedBox(height: 10.h),
                    AnimatedTextKit(
                      animatedTexts: [
                        TyperAnimatedText(
                          'Near Social',
                          textStyle: const TextStyle(
                            fontSize: 38.0,
                            fontWeight: FontWeight.bold,
                            color: NEARColors.white,
                          ),
                          speed: const Duration(milliseconds: 75),
                        ),
                      ],
                      totalRepeatCount: 1,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0.55.sh,
              child: ValueListenableBuilder(
                valueListenable: localyAuthenticated,
                builder: (context, val, _) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: val != null
                        ? AnimatedSwitcher(
                            duration: const Duration(seconds: 1),
                            switchInCurve: Curves.easeIn,
                            switchOutCurve: Curves.easeOut,
                            child: val
                                ? AuthenticatedBody(
                                    authenticatedStatusChanged:
                                        (authenticated) {
                                      localyAuthenticated.value = authenticated;
                                    },
                                  )
                                : const LoginBody(),
                          )
                        : const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StarryBackground extends StatefulWidget {
  const StarryBackground({super.key});

  @override
  _StarryBackgroundState createState() => _StarryBackgroundState();
}

class _StarryBackgroundState extends State<StarryBackground> {
  final Random _random = Random();
  final int _starCount = 100;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(_starCount, (index) => _buildStar(index)),
    );
  }

  Widget _buildStar(int index) {
    final double top =
        _random.nextDouble() * MediaQuery.of(context).size.height;
    final double left =
        _random.nextDouble() * MediaQuery.of(context).size.width;
    final int duration =
        _random.nextInt(3000) + 1000; // Random duration between 1 and 4 seconds

    return Positioned(
      top: top,
      left: left,
      child: AnimatedStar(duration: duration),
    );
  }
}

class AnimatedStar extends StatefulWidget {
  final int duration;

  const AnimatedStar({super.key, required this.duration});

  @override
  _AnimatedStarState createState() => _AnimatedStarState();
}

class _AnimatedStarState extends State<AnimatedStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.duration),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Icon(
        Icons.star,
        color: NEARColors.white,
        size: _random.nextDouble() * 3 + 1,
      ),
    );
  }
}
