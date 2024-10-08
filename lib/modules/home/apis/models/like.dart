class Like {
  String accountId;

  Like({
    required this.accountId,
  });

  @override
  String toString() {
    return 'Like(accountId: $accountId)';
  }

  @override
  operator ==(Object other) => other is Like && other.accountId == accountId;
  
  @override
  int get hashCode => accountId.hashCode;
  
}

