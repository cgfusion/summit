import '../entities/parent_portal_data.dart';

abstract interface class ParentPortalRepository {
  /// Null means the token is invalid/unknown -- deliberately no
  /// distinction from "token valid but no data" is exposed by the RPC.
  Future<ParentPortalData?> getPortalData(String token);

  /// Fetch portal data for all students associated with [parentIc].
  /// Optionally verifies against [childIc] for 2-factor authentication.
  Future<List<ParentPortalData>> getPortalDataByIc({
    required String parentIc,
    String? childIc,
  });
}
