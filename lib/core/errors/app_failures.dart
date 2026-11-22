

class AppSecurityException implements Exception {
  final String message;
  final String code;
  const AppSecurityException(this.message, {this.code = 'security_violation'});

  @override
  String toString() => 'AppSecurityException($code): $message';
}

class AppValidationFailure {
  final bool isValid;
  final String? errorMessage;
  const AppValidationFailure({required this.isValid, this.errorMessage});
}
