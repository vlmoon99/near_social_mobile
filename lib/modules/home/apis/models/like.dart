import 'package:equatable/equatable.dart';

class Like extends Equatable {
  final String accountId;

  const Like({
    required this.accountId,
  });

  @override
  List<Object?> get props => [accountId];
  
  @override
  bool? get stringify => true;
}
