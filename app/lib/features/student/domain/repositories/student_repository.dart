import '../entities/student.dart';

abstract interface class StudentRepository {
  Future<List<Student>> getStudents({String? classId, String? searchQuery});

  Future<Student?> getByStudentId(int studentId);

  Future<Student?> getById(String id);
}
