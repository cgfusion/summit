class StudentGuardian {
  const StudentGuardian({
    required this.id,
    required this.studentId,
    required this.fullName,
    this.relationship,
    this.icNumber,
    this.phone,
    this.email,
    required this.isPrimary,
    required this.isEmergencyContact,
    this.notes,
    required this.accessToken,
  });

  final String id;
  final String studentId;
  final String fullName;
  final String? relationship;
  final String? icNumber;
  final String? phone;
  final String? email;
  final bool isPrimary;
  final bool isEmergencyContact;
  final String? notes;

  /// The secret behind this guardian's parent-portal link
  /// (`/parent/<accessToken>`). Unauthenticated by design -- see
  /// fn_parent_portal_data.
  final String accessToken;

  factory StudentGuardian.fromMap(Map<String, dynamic> map) {
    return StudentGuardian(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      fullName: map['full_name'] as String,
      relationship: map['relationship'] as String?,
      icNumber: map['ic_number'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      isPrimary: map['is_primary'] as bool,
      isEmergencyContact: map['is_emergency_contact'] as bool,
      notes: map['notes'] as String?,
      accessToken: map['access_token'] as String,
    );
  }
}
