import '../entities/parent_portal_data.dart';

abstract interface class ParentPortalRepository {
  /// Null means the token is invalid/unknown -- deliberately no
  /// distinction from "token valid but no data" is exposed by the RPC.
  Future<ParentPortalData?> getPortalData(String token);
}
