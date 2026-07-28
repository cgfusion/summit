/// Outcome of attempting to bind a scanned QR token to a student.
sealed class RegisterQrResult {
  const RegisterQrResult();
}

/// Token is now the student's active card (freshly registered, or it was
/// already registered to this same student).
class RegisterQrSuccess extends RegisterQrResult {
  const RegisterQrSuccess();
}

/// This exact token is already active for a *different* student.
class RegisterQrTokenTaken extends RegisterQrResult {
  const RegisterQrTokenTaken(this.registeredToStudentName);

  final String registeredToStudentName;
}

/// The selected student already has a different active token. Caller should
/// confirm with the user, then call [reissueToken] to replace it.
class RegisterQrStudentHasToken extends RegisterQrResult {
  const RegisterQrStudentHasToken();
}
