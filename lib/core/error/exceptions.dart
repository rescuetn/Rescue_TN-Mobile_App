/// This file defines custom exception classes for the application.
/// These are used to represent specific error scenarios that can occur
/// in the data layer, such as server communication failures or cache errors.

/// Represents an error that occurs during a network request to a server (e.g., Firebase).
class ServerException implements Exception {
  final String message;
  ServerException({this.message = 'A server error occurred.'});
}

/// Represents an error that occurs when accessing local cache (e.g., Hive).
class CacheException implements Exception {
  final String message;
  CacheException({this.message = 'A cache error occurred.'});
}

/// Represents a general authentication-related error.
class AuthException implements Exception {
  final String message;
  AuthException({this.message = 'An authentication error occurred.'});
}
