import '../entities/school_class.dart';

abstract interface class ClassRepository {
  Future<List<SchoolClass>> getClasses();

  Future<SchoolClass?> getById(String id);
}
