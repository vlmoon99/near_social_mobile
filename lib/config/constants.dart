class SecureStorageKeys {
  static const authInfo = 'auth_info';
  static const cryptographicKey = 'cryptographic_key';
  static const additionalCryptographicKeys = 'additional_cryptographic_keys';
  static const networkType = 'network_type';
  static const appPolicyAccepted = 'app_policy_accepted';
}

class AppErrorCodes {
  static const errorFromZone = 0;
  static const errorFromFlutter = 1;
  static const invalidQRCodeFormat = 2;
  static const cryptoError = 3;
  static const storageError = 4;
  static const flutterchainError = 5;
  static const localAuthError = 6;
  static const testnetError = 7;
  static const nearSocialApiError = 8;
}

class NearAssets {
  static const logoIcon = "assets/media/icons/near_social_logo.svg";
  static const commentIcon = "assets/media/icons/comment_icon.svg";
  static const likeIcon = "assets/media/icons/like_icon.svg";
  static const activatedLikeIcon = "assets/media/icons/like_activated.svg";
  static const repostIcon = "assets/media/icons/repost_icon.svg";
  static const shareIcon = "assets/media/icons/share_icon.svg";
  static const standartAvatar = "assets/media/images/standart_avatar.png";
  static const widgetPlaceholder = "assets/media/images/widget_placeholder.png";
}

class NearUrls {
  static const blockchainRpc = "https://rpc.fastnear.com";
  static const nearSocialApi = "https://api.near.social";
  static const nearSocialIpfsMediaHosting = "https://ipfs.near.social/ipfs/";
}

class NearSocialMobileUrls {
  static const eulaUrl =
      "https://docs.google.com/document/d/1u0bmfj0OCtG0utsbR-xcPJVy0srEUf86N92rw8NOtEQ/edit";
  static const privacyPolicyUrl =
      "https://docs.google.com/document/d/1T-g8ZSH5Bg2_nUVOzUELmzK43a5UFp3o8G9pHnVb16k/edit";
}

const firebaseNearSocialProject = "near-social";

class FirebaseDatabasePathKeys {
  static const String usersPath = "users";
  //user blocks
  static const String userBlocskDir = "user_blocks";
  static const String blockedAccountsPath = "blocked_accounts";
  static const String hidedPostsPath = "hided_posts";
  static const String hidedCommentsPath = "hided_comments";
  //reports
  static const String reportsDir = "reports";
  static const String reportedPostsPath = "reported_posts";
  static const String reportedCommentsPath = "reported_comments";
  static const String reportedAccountsPath = "reported_accounts";
  //app settings

  static const String globalSettingsDir = "global_settings";
  static const String featuresSettingsPath = "features";
}
