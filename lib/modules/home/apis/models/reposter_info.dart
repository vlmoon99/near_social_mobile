// ignore_for_file: hash_and_equals

import 'package:near_social_mobile/modules/home/apis/models/general_account_info.dart';

class ReposterInfo {
  final GeneralAccountInfo accountInfo;
  final int blockHeight;

  ReposterInfo({
    required this.accountInfo,
    required this.blockHeight,
  });

  ReposterInfo copyWith({
    GeneralAccountInfo? accountInfo,
    int? blockHeight,
  }) {
    return ReposterInfo(
      accountInfo: accountInfo ?? this.accountInfo,
      blockHeight: blockHeight ?? this.blockHeight,
    );
  }

  @override
  operator ==(Object other) =>
      identical(this, other) ||
      other is ReposterInfo &&
          runtimeType == other.runtimeType &&
          accountInfo.accountId == other.accountInfo.accountId &&
          blockHeight == other.blockHeight;
}
