// ignore_for_file: overridden_fields

class Routes {
  static final _Auth auth = _Auth();
  static final _Home home = _Home();
}

class _Auth extends RouteClass {
  @override
  String module = '/auth';
  String qrReader = '/qr_reader';
  String encryptData = '/encrypt_data';
}

class _Home extends RouteClass {
  @override
  String module = '/home';
  String startPage = '/';
  String postPage = '/post';
  String postsFeed = '/posts_feed';
  String widgetsListPage = '/widgets_list';
  String widgetPage = '/widget';
  String peopleListPage = '/people_list';
  String userPage = '/profile';
  String homeMenu = '/home_menu';
  String notificationsPage = '/notifications';
  String keyManagerPage = '/key_manager';
  String settingsPage = '/settings';
  String blockedUsersPage = '/blocked_users';
  String hiddenPostsPage = '/hided_posts';
  String mintManager = '/mint_manager';
  String allMintbaseNftsPage = '/all_mintbase_nfts';
  String nftDetailsAndActionsPage = '/nft_details_and_actions';
  String mintbaseCollectionsPage = '/mintbase_collections';
  String mintersControlPage = '/minters_control';
  String mintNftPage = '/mint_nft';
}

abstract class RouteClass {
  String module = '/';

  String getRoute(String moduleRoute) => module + moduleRoute;

  String getModule() => '$module/';
}
