
class Reposter {
  String accountId;

  Reposter({
    required this.accountId,
  });

  @override
  operator ==(Object other) =>
      other is Reposter && other.accountId == accountId;

  @override
  int get hashCode => accountId.hashCode;
  
  @override
  String toString() {
    return 'Reposter(accountId: $accountId)';
  }
  
}