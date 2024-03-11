import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';

class QRAuthInfo {
  final String accountId;
  final String secretKey;

  QRAuthInfo(this.accountId, this.secretKey);
}

class QRFormatter {
  static QRAuthInfo convertURLToQRAuthInfo(String url) {
    final accountIdStartIndex = url.indexOf('a=');
    final secretKeyStartIndex = url.indexOf('&k=');

    final accountIdEndIndex = url.indexOf('&', accountIdStartIndex + 2);
    final secretKeyEndIndex = url.length;

    if (accountIdStartIndex == -1 ||
        secretKeyStartIndex == -1 ||
        accountIdEndIndex == -1 ||
        secretKeyEndIndex == -1) {
      throw AppExceptions(
        messageForUser: "Invalid QR code format",
        messageForDev:
            "Invalid QR code format $accountIdStartIndex, $secretKeyStartIndex, $accountIdEndIndex, $secretKeyEndIndex",
        statusCode: AppErrorCodes.invalidQRCodeFormat,
      );
    }

    final accountId = url.substring(accountIdStartIndex + 2, accountIdEndIndex);
    final secretKey = url.substring(secretKeyStartIndex + 3, secretKeyEndIndex);

    return QRAuthInfo(accountId, secretKey);
  }
}
