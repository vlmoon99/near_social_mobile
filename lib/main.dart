import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:near_social_mobile/assets/localizations/localizations_strings.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/app_module.dart';
import 'package:near_social_mobile/routes/routes.dart';
import 'package:near_social_mobile/utils/utils.dart';

import 'config/constants.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initOfApp();
    FlutterError.onError = (FlutterErrorDetails details) {
      final catcher = Modular.get<Catcher>();
      catcher.exceptionsHandler.add(AppExceptions(
        messageForUser: details.exceptionAsString(),
        messageForDev: details.exception.runtimeType.toString(),
        statusCode: AppErrorCodes.errorFromFlutter,
      ));
    };
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).then((_) {
      runApp(
        EasyLocalization(
          supportedLocales: const [
            Locale('en'),
          ],
          path: LocalizationsStrings.localizationPath,
          fallbackLocale: const Locale('en'),
          saveLocale: false,
          child: ModularApp(
            module: AppModule(),
            child: const AppWidget(),
          ),
        ),
      );
    });
  }, (error, stack) {
    final catcher = Modular.get<Catcher>();
    final appException = AppExceptions(
      messageForUser:
          ErrorMessageHandler.getErrorMessageForNotFlutterExceptions(error),
      messageForDev: error.toString(),
      statusCode: AppErrorCodes.errorFromZone,
    );
    catcher.exceptionsHandler.add(
      appException,
    );
  });
}

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    Modular.setInitialRoute(Routes.home.getModule());
    ScreenUtil.init(context);
    return MaterialApp.router(
      title: 'Near Social',
      debugShowCheckedModeBanner: false,
      routerConfig: Modular.routerConfig,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
