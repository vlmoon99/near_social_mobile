import 'package:equatable/equatable.dart';

class Follower extends Equatable {
  final String accountId;

  const Follower({required this.accountId});

  @override
  List<Object?> get props => [accountId];
  
  @override
  bool? get stringify => true;
}
