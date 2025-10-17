import 'package:equatable/equatable.dart';

/// A Failure is an object representing a user-facing error.
/// Instead of showing raw technical exceptions to the user, we convert them
/// into one of these Failure objects, which can contain a clean,
/// user-friendly error message. This is a core concept of clean architecture.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Represents a failure to communicate with a remote server (e.g., API, Firebase).
class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
}

/// Represents a failure to read from or write to the local cache.
class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

/// Represents a failure related to user authentication.
class AuthFailure extends Failure {
  const AuthFailure(String message) : super(message);
}
