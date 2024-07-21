import 'dart:math';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/config/theme.dart';
import 'package:near_social_mobile/modules/auth/pages/start_page/widgets/auth_body.dart';
import 'package:near_social_mobile/modules/auth/pages/start_page/widgets/login_body.dart';
import 'package:near_social_mobile/shared_widgets/custom_button.dart';
import 'package:near_social_mobile/utils/checkAppPolicyAccepted.dart';
import 'package:near_social_mobile/utils/checkAuthenticationOnDevice.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> showAcceptAppPolicy() async {
    return showDialog(
      barrierDismissible: false,
      context: Modular.routerDelegate.navigatorKey.currentContext!,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20).r,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text(
                'Welcome to Near Social Mobile!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5.h),
              Text.rich(
                style: const TextStyle(fontSize: 15),
                TextSpan(children: [
                  const TextSpan(
                    text: 'By using this app, you agree to the ',
                  ),
                  TextSpan(
                      text: 'End User License Agreement (EULA)',
                      style: const TextStyle(color: Colors.blue),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launchUrl(Uri.parse(NearSocialMobileUrls.eulaUrl));
                        }),
                  const TextSpan(text: ' and '),
                  TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(color: Colors.blue),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launchUrl(
                              Uri.parse(NearSocialMobileUrls.privacyPolicyUrl));
                        }),
                  const TextSpan(text: '.'),
                ]),
              ),
              SizedBox(height: 10.h),
              CustomButton(
                primary: true,
                onPressed: () {
                  final FlutterSecureStorage secureStorage =
                      Modular.get<FlutterSecureStorage>();
                  secureStorage.write(
                      key: SecureStorageKeys.appPolicyAccepted, value: 'true');
                  Modular.to.pop();
                },
                child: const Text(
                  'I AGREE',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ]),
          ),
        );
      },
    );
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

        final checkedAuthentication = await checkAuthenticationOnDevice();
        final appPolicyAccepted = await checkAppPolicyAccepted();

        if (!appPolicyAccepted) {
          showAcceptAppPolicy();
        }

        stopwatch.stop();

        final remainingTime =
            const Duration(milliseconds: 1000) - stopwatch.elapsed;

        if (remainingTime > Duration.zero) {
          await Future.delayed(remainingTime, () {
            localyAuthenticated.value = checkedAuthentication;
            _controller.forward();
          });
        } else {
          localyAuthenticated.value = checkedAuthentication;
          _controller.forward();
        }
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
