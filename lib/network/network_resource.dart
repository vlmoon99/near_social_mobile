import 'package:dio/dio.dart';

abstract class NetworkResource {
  final String baseUrl;
  final List<Interceptor> interceptors;
  int connectTimeout;
  int receiveTimeout;

  NetworkResource(this.baseUrl, this.interceptors,
      [this.connectTimeout = 5000, this.receiveTimeout = 3000]);
}
