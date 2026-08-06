import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/parent_portal_data.dart';
import '../../domain/repositories/parent_portal_repository.dart';

class ParentPortalRepositoryImpl implements ParentPortalRepository {
  ParentPortalRepositoryImpl({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<ParentPortalData?> getPortalData(String token) async {
    final result = await _client.rpc('fn_parent_portal_data', params: {'p_token': token});
    if (result == null) return null;
    return ParentPortalData.fromMap(result as Map<String, dynamic>);
  }

  @override
  Future<List<ParentPortalData>> getPortalDataByIc({
    required String parentIc,
    String? childIc,
  }) async {
    final result = await _client.rpc('fn_parent_portal_data_by_ic', params: {
      'p_parent_ic': parentIc,
      'p_child_ic': ?childIc,
    });
    if (result == null) return [];
    final list = result as List;
    return list.map((item) => ParentPortalData.fromMap(item as Map<String, dynamic>)).toList();
  }
}
