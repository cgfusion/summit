class StaffProfile {
  const StaffProfile({
    required this.id,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String fullName;
  final String role;

  factory StaffProfile.fromMap(Map<String, dynamic> map) {
    return StaffProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      role: map['role'] as String,
    );
  }
}
