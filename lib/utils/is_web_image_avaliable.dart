import 'package:dio/dio.dart';

Future<bool> isWebImageAvailable(String imageUrl) async {
  try {
    final dio = Dio();
    final response = await dio.head(imageUrl);

    if (response.statusCode == 200) {
      final contentType = response.headers.value('content-type');
      return contentType != null && contentType.startsWith('image/');
    }
  } catch (e) {
    return false;
  }
  return false;
}
