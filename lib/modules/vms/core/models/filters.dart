import 'package:json_annotation/json_annotation.dart';
part 'filters.g.dart'; // This is the generated file, name it accordingly

enum FilterLoadStatus { initial, loading, loaded }

@JsonSerializable()
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
          hidedAllPostsAccounts ?? this.hidedAllPostsAccounts,
    );
  }

  factory Filters.fromJson(Map<String, dynamic> json) {
    var filters = _$FiltersFromJson(json);
    return filters.copyWith(status: FilterLoadStatus.loaded);
  }

  Map<String, dynamic> toJson() => _$FiltersToJson(this);
}
