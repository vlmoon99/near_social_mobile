import 'dart:async';
import 'dart:convert';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:near_social_mobile/config/constants.dart';
import 'package:near_social_mobile/modules/vms/core/models/filters.dart';
import 'package:rxdart/rxdart.dart';

class FilterController extends Disposable {
  final FlutterSecureStorage storage;
  FilterController(this.storage);

  final BehaviorSubject<Filters> _streamController =
      BehaviorSubject.seeded(const Filters());

  Stream<Filters> get stream => _streamController.stream;
  Filters get state => _streamController.value;

  Future<void> loadFilters() async {
    _streamController.add(state.copyWith(status: FilterLoadStatus.loading));
    final Map<String, dynamic> filters =
        jsonDecode(await storage.read(key: SecureStorageKeys.filters) ?? "{}");
    if (filters.isEmpty) {
      _streamController.add(state.copyWith(status: FilterLoadStatus.loaded));
      return;
    }
    final actualFilters = Filters.fromJson(filters);
    _streamController.add(actualFilters);
  }

  Future<void> blockUser(
      {required String accountId, required String blockedAccountId}) async {
    _streamController.add(state.copyWith(
      blockedAccounts: [...state.blockedAccounts, blockedAccountId],
    ));
    _updateFilters();
  }

  Future<void> unblockUser(
      {required String accountId, required String blockedAccountId}) async {
    _streamController.add(state.copyWith(
      blockedAccounts: List.of(state.blockedAccounts)..remove(blockedAccountId),
    ));
    _updateFilters();
  }

  Future<void> hidePost(
      {required String accountId,
      required String accountIdToHide,
      required int blockHeightToHide}) async {
    _streamController.add(state.copyWith(
      hidedPosts: [...state.hidedPosts, "$accountIdToHide&$blockHeightToHide"],
    ));
    _updateFilters();
  }

  Future<void> hidePostsOfUser(
      {required String accountId, required String accountIdToHide}) async {
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
    _updateFilters();
  }

  Future<void> restorePostsOfUser(
      {required String accountId, required String accountIdToRestore}) async {
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
    _updateFilters();
  }

  Future<void> _updateFilters() async {
    return storage.write(
      key: SecureStorageKeys.filters,
      value: jsonEncode(state.toJson()),
    );
  }

  Future<void> clear() async {
    _streamController.add(const Filters());
    await storage.delete(key: SecureStorageKeys.filters);
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
