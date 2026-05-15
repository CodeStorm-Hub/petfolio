import 'package:supabase_flutter/supabase_flutter.dart';

sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'A network error occurred.']);
}

final class NotAuthenticatedException extends AppException {
  const NotAuthenticatedException()
      : super('User must be authenticated to perform this action.');
}

final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'The requested resource was not found.']);
}

final class ValidationException extends AppException {
  const ValidationException(super.message);
}

final class DatabaseException extends AppException {
  const DatabaseException(super.message);

  factory DatabaseException.fromPostgrest(PostgrestException e) =>
      DatabaseException(e.message);
}
