import 'package:easy_localization/easy_localization.dart';
import 'package:flutterchain/flutterchain_lib/services/core/lib_initialization_service.dart';

Future<void> initOfApp() async {
  await EasyLocalization.ensureInitialized();
  initFlutterChainLib();
}
