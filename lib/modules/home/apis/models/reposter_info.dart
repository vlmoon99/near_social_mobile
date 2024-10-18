// ignore_for_file: hash_and_equals

import 'package:equatable/equatable.dart';
import 'package:near_social_mobile/modules/home/apis/models/general_account_info.dart';

class ReposterInfo extends Equatable {
  final GeneralAccountInfo accountInfo;
  final int blockHeight;

  const ReposterInfo({
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
  List<Object?> get props => [accountInfo.accountId, blockHeight];

  @override
  bool? get stringify => true;
}
