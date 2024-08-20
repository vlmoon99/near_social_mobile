import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/modules/auth/pages/encryption_screen.dart';
import 'package:near_social_mobile/routes/routes.dart';

import 'pages/qr_scan_screen.dart';

class AuthModule extends Module {
  @override
  void routes(RouteManager r) {
    r.child(
      Routes.auth.qrReader,
      child: (context) => const QRReaderScreen(),
    );
    r.child(
      Routes.auth.encryptData,
      child: (context) => EncryptionScreen(
        authorizationCredentials: r.args.data,
      ),
    );
  }
}
