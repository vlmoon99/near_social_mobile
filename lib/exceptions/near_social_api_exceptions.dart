class IncorrectNonceException implements Exception {
  final Map<String, dynamic> data;

  IncorrectNonceException({required this.data});
}
