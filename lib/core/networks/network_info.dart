// Exceptions (Data layer throws these)
class ServerException implements Exception {
  final String message;
  ServerException({this.message = 'Server error occurred'});
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException({this.message = 'Database error occurred'});
}

class CacheException implements Exception {
  final String message;
  CacheException({this.message = 'Cache error occurred'});
}

class AuthException implements Exception {
  final String message;
  AuthException({this.message = 'Authentication failed'});
}

// Failures (Domain layer uses these)
abstract class Failure {
  final String message;
  const Failure({required this.message});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}
