// ignore_for_file: hash_and_equals

class ReposterInfo {
  final String accountId;
  final String? name;
  final int blockHeight;

  ReposterInfo({
    required this.accountId,
    this.name,
    required this.blockHeight,
  });

  ReposterInfo copyWith({
    String? accountId,
    String? name,
    int? blockHeight,
  }) {
    return ReposterInfo(
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      blockHeight: blockHeight ?? this.blockHeight,
    );
  }

  @override
  operator ==(Object other) =>
      other is ReposterInfo &&
      other.blockHeight == blockHeight &&
      other.accountId == accountId;
}
