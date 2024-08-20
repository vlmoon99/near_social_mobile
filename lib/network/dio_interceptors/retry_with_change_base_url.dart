import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

class RetryInterceptorWithSecondaryLink extends RetryInterceptor {
  final String primaryLink;
  final String secondaryLink;

  RetryInterceptorWithSecondaryLink({
    required super.dio,
    super.retries,
    super.logPrint,
    super.retryDelays,
    required this.primaryLink,
    required this.secondaryLink,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final newOptions = options.copyWith(
      baseUrl:
          options.attempt < (super.retries ~/ 2) ? primaryLink : secondaryLink,
    );
    super.onRequest(newOptions, handler);
  }
}