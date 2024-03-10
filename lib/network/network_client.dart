import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:near_social_mobile/exceptions/exceptions.dart';
import 'package:near_social_mobile/network/network_resource.dart';

class NetworkClient {
  late Dio dio;
  final Catcher catcher;
  final NetworkResource networkResource;

  NetworkClient(this.catcher, this.networkResource) {
    dio = Dio();
    dio.options.baseUrl = networkResource.baseUrl;
    dio.options.connectTimeout =
        Duration(seconds: networkResource.connectTimeout);
    dio.options.receiveTimeout =
        Duration(seconds: networkResource.receiveTimeout);

    for (var element in networkResource.interceptors) {
      dio.interceptors.add(element);
    }
  }

  AppExceptions handleError(DioException e) {
    final details = jsonDecode(e.response!.data)['detail'];
    final exception = AppExceptions(
      messageForUser: details,
      messageForDev: e.error.toString(),
      statusCode: e.response!.statusCode!,
    );
    catcher.exceptionsHandler.add(exception);
    return exception;
  }

  Future<ApiResponse> getRequest(String url) async {
    AppExceptions? appExceptions;
    try {
      Response response = await dio.get(url);
      return ApiResponse.success(response.data, response.statusCode!, true);
    } on DioException catch (e) {
      appExceptions = handleError(e);
    }
    return ApiResponse.error(
        appExceptions.messageForDev, appExceptions.statusCode, false);
  }

  Future<ApiResponse> postHTTP(String url, dynamic data) async {
    AppExceptions? appExceptions;

    try {
      Response response = await dio.post(
        url,
        data: data,
      );
      return ApiResponse.success(response.data, response.statusCode!, true);
    } on DioException catch (e) {
      appExceptions = handleError(e);
    }
    return ApiResponse.error(
        appExceptions.messageForDev, appExceptions.statusCode, false);
  }

  Future<ApiResponse> putHTTP(String url, dynamic data) async {
    AppExceptions? appExceptions;

    try {
      Response response = await dio.put(url, data: data);
      return ApiResponse.success(response.data, response.statusCode!, true);
    } on DioException catch (e) {
      appExceptions = handleError(e);
    }
    return ApiResponse.error(
        appExceptions.messageForDev, appExceptions.statusCode, false);
  }

  Future<ApiResponse> deleteHTTP(String url, dynamic data) async {
    AppExceptions? appExceptions;

    try {
      Response response = await dio.delete(url, data: data);
      return ApiResponse.success(response.data, response.statusCode!, true);
    } on DioException catch (e) {
      appExceptions = handleError(e);
    }

    return ApiResponse.error(
        appExceptions.messageForDev, appExceptions.statusCode, false);
  }
}

class ApiResponse {
  ApiResponse.success(this.data, this.statusCode, this.isSuccess);
  ApiResponse.error(this.data, this.statusCode, this.isSuccess);

  dynamic data;
  int statusCode;
  bool isSuccess;
}
