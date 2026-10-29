class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server error']);
  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  AuthException([this.message = 'Authentication error']);
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network error']);
  @override
  String toString() => message;
}
