import 'package:equatable/equatable.dart';

class Nft extends Equatable {
  final String contractId;
  final String tokenId;
  final String title;
  final String description;
  final String imageUrl;

  const Nft({
    required this.contractId,
    required this.tokenId,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  @override
  List<Object?> get props =>
      [contractId, tokenId, title, description, imageUrl];

  @override
  bool? get stringify => true;
}
