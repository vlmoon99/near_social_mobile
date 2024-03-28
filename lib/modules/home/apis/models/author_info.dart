// ignore_for_file: hash_and_equals

class AuthorInfo {
  final String accountId;
  final String? name;
  final String profileImageLink;

  AuthorInfo({
    required this.accountId,
    this.name,
    required this.profileImageLink,
  });

  @override
  operator ==(Object other) =>
      other is AuthorInfo &&
      other.accountId == accountId &&
      other.name == name &&
      other.profileImageLink == profileImageLink;
}
