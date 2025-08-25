class ServerException implements Exception {}

class CacheException implements Exception {}

class DatabaseException implements Exception {
  final String message;

  const DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}

class PermissionException implements Exception {
  final String message;

  const PermissionException(this.message);

  @override
  String toString() => 'PermissionException: $message';
}

class NotificationException implements Exception {
  final String message;

  const NotificationException(this.message);

  @override
  String toString() => 'NotificationException: $message';
}
