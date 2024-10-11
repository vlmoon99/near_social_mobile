class Nft {
  final String contractId;
  final String tokenId;
  final String title;
  final String description;
  final String imageUrl;

  Nft({
    required this.contractId,
    required this.tokenId,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

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
          tokenId == other.tokenId &&
          imageUrl == other.imageUrl;
}
