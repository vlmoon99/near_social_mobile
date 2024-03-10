// ignore_for_file: overridden_fields

class Routes {
  static final _Auth auth = _Auth();
  static final _Home home = _Home();
}

class _Auth extends RouteClass {
  @override
  String module = '/auth';
  String login = '/';
}

class _Home extends RouteClass {
  @override
  String module = '/home';
  String startPage = '/';
}

abstract class RouteClass {
  String module = '/';

  String getRoute(String moduleRoute) => module + moduleRoute;

  String getModule() => '$module/';
}
