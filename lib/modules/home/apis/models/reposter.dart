import 'package:equatable/equatable.dart';

class Reposter extends Equatable {
  final String accountId;

  const Reposter({
    required this.accountId,
  });

  @override
  List<Object?> get props => [accountId];
      
  @override
  bool? get stringify => true;
}
