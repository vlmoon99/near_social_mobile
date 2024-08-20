class LocalizationsStrings {
  static final _Auth auth = _Auth();
  static final _Home home = _Home();
  static const localizationPath = './assets/translations';
}

class _Auth {
  final login = _Login();
}

class _Home {
  final title = 'launch.title';
}

class _Login {
  final title = 'login.title';
}
