class Nft {
  final String contractId;
  final String tokenId;
  final String title;
  final String description;

  Nft({
    required this.contractId,
    required this.tokenId,
    required this.title,
    required this.description,
  });

  String get imageUrl =>
      "https://i.near.social/magic/large/https://near.social/magic/img/nft/$contractId/$tokenId";

  @override
  String toString() {
    return 'Nft{contractId: $contractId, tokenId: $tokenId, title: $title, description: $description, imageUrl: $imageUrl}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Nft &&
          runtimeType == other.runtimeType &&
          contractId == other.contractId &&
          tokenId == other.tokenId;
}
