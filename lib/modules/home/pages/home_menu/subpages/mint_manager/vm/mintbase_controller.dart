import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutterchain/flutterchain_lib/constants/core/blockchain_response.dart';
import 'package:flutterchain/flutterchain_lib/models/chains/near/mintbase_category_nft.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/modules/home/apis/models/nft.dart';
import 'package:near_social_mobile/modules/home/apis/near_social.dart';
import 'package:rxdart/rxdart.dart';

class MintbaseController {
  final NearBlockChainService nearBlockChainService;
  final NearSocialApi nearSocialApi;

  MintbaseController({
    required this.nearBlockChainService,
    required this.nearSocialApi,
  });

  final BehaviorSubject<MintbaseAccountState> _streamController =
      BehaviorSubject<MintbaseAccountState>.seeded(
    const MintbaseAccountState(),
  );

  Stream<MintbaseAccountState> get stream =>
      _streamController.stream.distinct();

  MintbaseAccountState get state => _streamController.value;

  Future<void> loadAccountInfo(String accountId) async {
    _streamController.add(
        state.copyWith(loadStatus: MintbaseAccountStateLoadStatus.loading));

    final ownCollectionsIds = List<String>.from(
        await nearBlockChainService.checkOwnerCollection(owner_id: accountId));

    final ownCollections = ownCollectionsIds.map(
      (collectionId) {
        return MintbaseCollection(
          contractId: collectionId,
        );
      },
    ).toList();

    final nftList =
        await nearSocialApi.getMintbaseNfts(accountIdOfUser: accountId);

    _streamController.add(state.copyWith(
      loadStatus: MintbaseAccountStateLoadStatus.loaded,
      ownCollections: ownCollections,
      nftList: nftList,
    ));
  }

  Future<void> updateOwnCollections(String accountId) async {
    final ownCollections = List<String>.from(
        await nearBlockChainService.checkOwnerCollection(owner_id: accountId));

    final newOwnCollections = List.of(state.ownCollections
        .where((collection) => ownCollections.contains(collection.contractId))
        .toList());

    for (final collectionId in ownCollections) {
      if (!newOwnCollections
          .any((collection) => collection.contractId == collectionId)) {
        newOwnCollections.add(
          MintbaseCollection(
            contractId: collectionId,
          ),
        );
      }
    }
    _streamController.add(state.copyWith(ownCollections: newOwnCollections));
  }

  Future<void> updateCollectionMinters({
    required String accountId,
    required String publicKey,
    required String privateKey,
    required String nftCollectionContract,
  }) async {
    final mintersIds = List<String>.from(
      await nearBlockChainService.getMinters(
        accountId: accountId,
        publicKey: publicKey,
        privateKey: privateKey,
        nftCollectionContract: nftCollectionContract,
      ),
    );

    final collectionIndex = state.ownCollections.indexWhere(
        (collection) => collection.contractId == nftCollectionContract);

    _streamController.add(
      state.copyWith(
        ownCollections: List.of(state.ownCollections)
          ..[collectionIndex] = state.ownCollections[collectionIndex].copyWith(
            mintersIds: mintersIds,
            lastUpdate: DateTime.now(),
          ),
      ),
    );
  }

  Future<void> updateNftList(String accountId) async {
    final nftList =
        await nearSocialApi.getMintbaseNfts(accountIdOfUser: accountId);
    _streamController.add(state.copyWith(nftList: nftList));
  }

  Future<String> transferNft({
    required String accountId,
    required String publicKey,
    required String privateKey,
    required String nftCollectionContract,
    required String nftId,
    required String receiverAccountId,
  }) async {
    try {
      final response = await nearBlockChainService.transferNFT(
        accountId: accountId,
        publicKey: publicKey,
        privateKey: privateKey,
        nftCollectionContract: nftCollectionContract,
        tokenIds: [
          [nftId, receiverAccountId]
        ],
      );
      if (response.status != BlockchainResponses.success) {
        throw AppExceptions(
          messageForUser: "Failed to transfer NFT. ${response.data["error"]}",
          messageForDev: response.data["error"].toString(),
        );
      }
      _streamController.add(
        state.copyWith(
          nftList: List.of(state.nftList)
            ..removeWhere(
              (nft) {
                return nft.tokenId == nftId &&
                    nft.contractId == nftCollectionContract;
              },
            ),
        ),
      );
      return response.data["txHash"];
    } on AppExceptions catch (_) {
      rethrow;
    } catch (err) {
      throw AppExceptions(
          messageForUser: err.toString(), messageForDev: err.toString());
    }
  }

  Future<String> createCollection({
    required String accountId,
    required String publicKey,
    required String privateKey,
    required String collectionSymbol,
    required String collectionName,
  }) async {
    final response = await nearBlockChainService.deployNFTCollection(
      accountId: accountId,
      publicKey: publicKey,
      privateKey: privateKey,
      symbol: collectionSymbol,
      name: collectionName,
      ownerId: accountId,
    );

    if (response.status != BlockchainResponses.success) {
      throw AppExceptions(
        messageForUser:
            "Failed to create collection. ${response.data["error"]}",
        messageForDev: response.data["error"].toString(),
      );
    }

    _streamController.add(
      state.copyWith(
        ownCollections: List.of(state.ownCollections)
          ..add(
            MintbaseCollection(
              contractId: "$collectionName.mintbase1.near",
            ),
          ),
      ),
    );

    return response.data["txHash"];
  }

  Future<String> removeMinterFromCollection({
    required String accountId,
    required String publicKey,
    required String privateKey,
    required String nftCollectionContract,
    required String minterAccountId,
  }) async {
    final response = await nearBlockChainService.addDeleteMinters(
      accountId: accountId,
      publicKey: publicKey,
      privateKey: privateKey,
      nftCollectionContract: nftCollectionContract,
      name: minterAccountId,
      isAdd: false,
    );

    if (response.status != BlockchainResponses.success) {
      throw AppExceptions(
        messageForUser: "Failed to remove minter. ${response.data["error"]}",
        messageForDev: response.data["error"].toString(),
      );
    }

    final collectionIndex = state.ownCollections.indexWhere(
        (collection) => collection.contractId == nftCollectionContract);

    _streamController.add(
      state.copyWith(
        ownCollections: List.of(state.ownCollections)
          ..[collectionIndex] = state.ownCollections[collectionIndex].copyWith(
            mintersIds:
                List.of(state.ownCollections[collectionIndex].mintersIds ?? [])
                  ..removeWhere(
                    (element) => element == minterAccountId,
                  ),
          ),
      ),
    );

    return response.data["txHash"];
  }

  Future<String> addMinterToCollection({
    required String accountId,
    required String publicKey,
    required String privateKey,
    required String nftCollectionContract,
    required String minterAccountId,
  }) async {
    final response = await nearBlockChainService.addDeleteMinters(
      accountId: accountId,
      publicKey: publicKey,
      privateKey: privateKey,
      nftCollectionContract: nftCollectionContract,
      name: minterAccountId,
      isAdd: true,
    );

    if (response.status != BlockchainResponses.success) {
      throw AppExceptions(
        messageForUser: "Failed to add minter. ${response.data["error"]}",
        messageForDev: response.data["error"].toString(),
      );
    }

    final collectionIndex = state.ownCollections.indexWhere(
        (collection) => collection.contractId == nftCollectionContract);

    _streamController.add(
      state.copyWith(
        ownCollections: List.of(state.ownCollections)
          ..[collectionIndex] = state.ownCollections[collectionIndex].copyWith(
            mintersIds:
                List.of(state.ownCollections[collectionIndex].mintersIds ?? [])
                  ..add(minterAccountId),
          ),
      ),
    );

    return response.data["txHash"];
  }

  Future<String> transferNftCollection({
    required String accountId,
    required String publicKey,
    required String privateKey,
    required String nftCollectionContract,
    required String newOwnerAccountId,
    required bool keepOldMintersFlag,
  }) async {
    final response = await nearBlockChainService.transferNFTCollection(
      accountId: accountId,
      publicKey: publicKey,
      privateKey: privateKey,
      nftCollectionContract: nftCollectionContract,
      new_owner: newOwnerAccountId,
      keep_old_minters: keepOldMintersFlag,
    );

    if (response.status != BlockchainResponses.success) {
      throw AppExceptions(
        messageForUser:
            "Failed to transfer collection. ${response.data["error"]}",
        messageForDev: response.data["error"].toString(),
      );
    }

    _streamController.add(
      state.copyWith(
        ownCollections: List.of(state.ownCollections)
          ..removeWhere(
            (collection) => collection.contractId == nftCollectionContract,
          ),
      ),
    );

    return response.data["txHash"];
  }

  Future<String> mintNft({
    required String accountId,
    required String publicKey,
    required String privateKey,
    required String nftCollectionContract,
    required String title,
    required String description,
    required Uint8List media,
    required Map<String, int>? splitBetween,
    required Map<String, int>? splitOwners,
    required List<String>? tagsList,
    required CategoryNFT category,
    required int numToMint,
  }) async {
    try {
      final response = await nearBlockChainService.mintNFT(
        owner_id: accountId,
        accountId: accountId,
        publicKey: publicKey,
        privateKey: privateKey,
        nftCollectionContract: nftCollectionContract,
        title: title,
        description: description,
        media: media,
        split_between: splitBetween,
        split_owners: splitOwners,
        tags: tagsList,
        category: category,
        num_to_mint: numToMint,
      );

      if (response.status != BlockchainResponses.success) {
        throw AppExceptions(
          messageForUser: "Failed to mint NFT. ${response.data["error"]}",
          messageForDev: response.data["error"].toString(),
        );
      }

      Future.delayed(
        const Duration(seconds: 3),
        () {
          updateNftList(accountId);
        },
      );

      return response.data["txHash"];
    } on AppExceptions catch (_) {
      rethrow;
    } catch (err) {
      throw AppExceptions(
        messageForUser: err.toString(),
        messageForDev: err.toString(),
      );
    }
  }

  Future<String> copyNft({
    required String accountId,
    required String publicKey,
    required String privateKey,
    required String nftCollectionContract,
    required String nftTitle,
    required int count,
  }) async {
    try {
      final response = await nearBlockChainService.multiplyNFT(
        nameNFTCollection: nftCollectionContract,
        nameNFT: nftTitle,
        accountId: accountId,
        publicKey: publicKey,
        privateKey: privateKey,
        numToMint: count,
      );

      if (response.status != BlockchainResponses.success) {
        throw AppExceptions(
          messageForUser: "Failed to copy NFT. ${response.data["error"]}",
          messageForDev: response.data["error"].toString(),
        );
      }

      Future.delayed(
        const Duration(seconds: 3),
        () {
          updateNftList(accountId);
        },
      );

      return response.data["txHash"];
    } on AppExceptions catch (_) {
      rethrow;
    } catch (err) {
      throw AppExceptions(
        messageForUser: err.toString(),
        messageForDev: err.toString(),
      );
    }
  }
}

enum MintbaseAccountStateLoadStatus { init, loading, loaded }

class MintbaseAccountState extends Equatable {
  final MintbaseAccountStateLoadStatus loadStatus;
  final List<MintbaseCollection> ownCollections;
  final List<Nft> nftList;

  const MintbaseAccountState({
    this.loadStatus = MintbaseAccountStateLoadStatus.init,
    this.ownCollections = const [],
    this.nftList = const [],
  });

  MintbaseAccountState copyWith({
    MintbaseAccountStateLoadStatus? loadStatus,
    List<MintbaseCollection>? ownCollections,
    List<Nft>? nftList,
  }) {
    return MintbaseAccountState(
      loadStatus: loadStatus ?? this.loadStatus,
      ownCollections: ownCollections ?? this.ownCollections,
      nftList: nftList ?? this.nftList,
    );
  }

  @override
  List<Object?> get props => [loadStatus, ownCollections, nftList];

  @override
  bool? get stringify => true;
}

class MintbaseCollection extends Equatable {
  final String contractId;
  final List<String>? mintersIds;
  final DateTime? lastUpdate;

  const MintbaseCollection({
    required this.contractId,
    this.lastUpdate,
    this.mintersIds,
  });

  MintbaseCollection copyWith(
      {String? contractId, DateTime? lastUpdate, List<String>? mintersIds}) {
    return MintbaseCollection(
      contractId: contractId ?? this.contractId,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      mintersIds: mintersIds ?? this.mintersIds,
    );
  }

  @override
  List<Object?> get props => [contractId, lastUpdate, mintersIds];

  @override
  bool? get stringify => true;
}
