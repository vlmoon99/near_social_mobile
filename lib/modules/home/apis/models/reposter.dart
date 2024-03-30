// ignore_for_file: hash_and_equals

class Reposter {
  String accountId;

  Reposter({
    required this.accountId,
  });

  @override
  operator ==(Object other) =>
      other is Reposter && other.accountId == accountId;

  @override
  String toString() {
    return 'Reposter(accountId: $accountId)';
  }
}