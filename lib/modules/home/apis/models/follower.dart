class Follower {
  final String accountId;

  Follower({required this.accountId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Follower &&
          runtimeType == other.runtimeType &&
          accountId == other.accountId;
}
