import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/services/firebase/near_social_project/firestore_database.dart';
import 'package:rxdart/rxdart.dart';

class FilterController extends Disposable {
  String _dbPathToFilters(String accountId) =>
      "${FirebaseDatabasePathKeys.usersPath}/$accountId/${FirebaseDatabasePathKeys.userBlocskDir}";

  final BehaviorSubject<Filters> _streamController =
      BehaviorSubject.seeded(const Filters());

  Stream<Filters> get stream => _streamController.stream;
  Filters get state => _streamController.value;

  Future<void> loadFilters(String accountId) async {
    _streamController.add(state.copyWith(status: FilterLoadStatus.loading));
    final Map<String, dynamic> filters =
        await FirebaseDatabaseService.getAllRecordsOfCollection(
            "${FirebaseDatabasePathKeys.usersPath}/$accountId/user_blocks");
    if (filters.isEmpty) {
      return;
    }
    final actualFilters = Filters.fromJson(filters);
    _streamController.add(actualFilters);
  }

  Future<void> blockUser(
      {required String accountId, required String blockedAccountId}) async {
    await FirebaseDatabaseService.updateBySetWithMergeRecordByPath(
      "${_dbPathToFilters(accountId)}/${FirebaseDatabasePathKeys.blockedAccountsPath}",
      {blockedAccountId: {}},
    );
    _streamController.add(state.copyWith(
      blockedAccounts: [...state.blockedAccounts, blockedAccountId],
    ));
  }

  Future<void> unblockUser(
      {required String accountId, required String blockedAccountId}) async {
    await FirebaseDatabaseService.updateBySetWithMergeRecordByPath(
        "${_dbPathToFilters(accountId)}/${FirebaseDatabasePathKeys.blockedAccountsPath}",
        {
          blockedAccountId: FieldValue.delete(),
        });
    _streamController.add(state.copyWith(
      blockedAccounts: List.of(state.blockedAccounts)..remove(blockedAccountId),
    ));
  }

  Future<void> hidePost(
      {required String accountId,
      required String accountIdToHide,
      required int blockHeightToHide}) async {
    final String hidedPostsPathFullPath =
        "${_dbPathToFilters(accountId)}/${FirebaseDatabasePathKeys.hidedPostsPath}";
    await FirebaseDatabaseService.updateBySetWithMergeRecordByPath(
      hidedPostsPathFullPath,
      {
        accountIdToHide: FieldValue.arrayUnion([blockHeightToHide])
      },
    );
    _streamController.add(state.copyWith(
      hidedPosts: [...state.hidedPosts, "$accountIdToHide&$blockHeightToHide"],
    ));
  }

  Future<void> hidePostsOfUser(
      {required String accountId, required String accountIdToHide}) async {
    final String hidedPostsPathFullPath =
        "${_dbPathToFilters(accountId)}/${FirebaseDatabasePathKeys.hidedPostsPath}";
    await FirebaseDatabaseService.updateBySetWithMergeRecordByPath(
      hidedPostsPathFullPath,
      {accountIdToHide: true},
    );
    _streamController.add(
      state.copyWith(
        hidedAllPostsAccounts: [
          ...state.hidedAllPostsAccounts,
          accountIdToHide
        ],
        hidedPosts: List.of(state.hidedPosts)
          ..removeWhere(
            (element) => element.startsWith("$accountIdToHide&"),
          ),
      ),
    );
  }

  Future<void> restorePostsOfUser(
      {required String accountId, required String accountIdToRestore}) async {
    final String hidedPostsPathFullPath =
        "${_dbPathToFilters(accountId)}/${FirebaseDatabasePathKeys.hidedPostsPath}";
    await FirebaseDatabaseService.updateBySetWithMergeRecordByPath(
      hidedPostsPathFullPath,
      {accountIdToRestore: FieldValue.delete()},
    );
    _streamController.add(
      state.copyWith(
        hidedAllPostsAccounts: List.of(state.hidedAllPostsAccounts)
          ..remove(accountIdToRestore),
        hidedPosts: List.of(state.hidedPosts)
          ..removeWhere(
            (element) => element.startsWith("$accountIdToRestore&"),
          ),
      ),
    );
  }

  Future<void> sendReport({
    required String accountId,
    required String message,
    required String accountIdToReport,
    int? blockHeightToReport,
    required String reportType,
  }) async {
    final path =
        "${FirebaseDatabasePathKeys.reportsDir}/$accountId/$reportType/${DateTime.now().toIso8601String()}";
    await FirebaseDatabaseService.updateBySetWithMergeRecordByPath(path, {
      "message": message,
      "accountIdToReport": accountIdToReport,
      if (blockHeightToReport != null)
        "blockHeightToReport": blockHeightToReport,
    });
  }

  Future<void> clear() async {
    _streamController.add(const Filters());
  }

  @override
  void dispose() {
    _streamController.close();
  }
}

class FiltersUtil {
  final Filters filters;

  FiltersUtil({required this.filters});

  bool postIsHided(String accountId, int blockHeight) {
    return filters.blockedAccounts.contains(accountId) ||
        filters.hidedPosts.contains("$accountId&$blockHeight") ||
        filters.hidedAllPostsAccounts.contains(accountId);
  }

  bool commentIsHided(String accountId, int blockHeight) {
    return filters.blockedAccounts.contains(accountId);
  }

  bool userIsBlocked(String accountId) {
    return filters.blockedAccounts.contains(accountId);
  }
}

enum FilterLoadStatus { initial, loading, loaded }

@immutable
class Filters {
  final FilterLoadStatus status;
  final List<String> blockedAccounts;
  final List<String> hidedPosts;
  final List<String> hidedAllPostsAccounts;

  const Filters({
    this.status = FilterLoadStatus.initial,
    this.blockedAccounts = const [],
    this.hidedPosts = const [],
    this.hidedAllPostsAccounts = const [],
  });

  ({String accountId, int blockHeight}) convertIdToCredentials(String id) {
    final splittedID = id.split("&");
    return (
      accountId: splittedID.first,
      blockHeight: int.parse(splittedID.last)
    );
  }

  List<String> get allHiddenPostsUsers => List.of(hidedAllPostsAccounts)
    ..addAll(hidedPosts.map(
      (fullId) {
        return fullId.split("&")[0];
      },
    ).toSet());

  Filters copyWith({
    FilterLoadStatus? status,
    List<String>? blockedAccounts,
    List<String>? hidedPosts,
    List<String>? hidedAllPostsAccounts,
  }) {
    return Filters(
        status: status ?? this.status,
        blockedAccounts: blockedAccounts ?? this.blockedAccounts,
        hidedPosts: hidedPosts ?? this.hidedPosts,
        hidedAllPostsAccounts:
            hidedAllPostsAccounts ?? this.hidedAllPostsAccounts);
  }

  static Filters fromJson(Map<String, dynamic> filters) {
    List<String> convertMapToListFullIDs(dynamic value) {
      if (value == null) {
        return [];
      }
      List<String> result = [];

      final mappedValue = Map<String, dynamic>.from(value);

      mappedValue.forEach((key, value) {
        if (value is! bool) {
          final blockheights = List<int>.from(value);
          for (var element in blockheights) {
            result.add("$key&$element");
          }
        }
      });
      return result;
    }

    List<String> convertMapToListIDs(dynamic value) {
      if (value == null) {
        return [];
      }
      List<String> result = [];

      final mappedValue = Map<String, dynamic>.from(value);

      mappedValue.forEach((key, value) {
        if (value is bool) {
          result.add(key);
        }
      });
      return result;
    }

    return Filters(
      status: FilterLoadStatus.loaded,
      blockedAccounts: List<String>.from(Map<String, dynamic>.from(
              filters[FirebaseDatabasePathKeys.blockedAccountsPath] ?? {})
          .keys
          .toList()),
      hidedPosts: convertMapToListFullIDs(
          filters[FirebaseDatabasePathKeys.hidedPostsPath]),
      hidedAllPostsAccounts:
          convertMapToListIDs(filters[FirebaseDatabasePathKeys.hidedPostsPath]),
    );
  }
}
