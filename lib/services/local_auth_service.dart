
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';

class LocalAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate({required String requestAuthMessage}) async {
    try {
      final bool authenticated = await _auth.authenticate(
        localizedReason: requestAuthMessage,
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );
      return authenticated;
    } on PlatformException catch (err) {
      throw AppExceptions(
        messageForUser: 'You have to enable password protection on your device',
        messageForDev: err.toString(),
      );
    } catch (err) {
      throw Exception(err.toString());
    }
  }
}
