abstract class Failure {
  final String message;
  Failure({required this.message});
}

class AuthException implements Exception {
  final String message;
  AuthException({required this.message});

  @override
  String toString() => message;
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException({required this.message});

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException({required this.message});

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  ServerFailure({required String message}) : super(message: message);
}

class NetworkFailure extends Failure {
  NetworkFailure({required String message}) : super(message: message);
}

class DatabaseFailure extends Failure {
  DatabaseFailure({required String message}) : super(message: message);
}

class AuthFailure extends Failure {
  AuthFailure({required String message}) : super(message: message);
}
