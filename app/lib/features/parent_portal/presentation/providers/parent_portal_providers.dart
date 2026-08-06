import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../data/repositories/parent_portal_repository_impl.dart';
import '../../domain/entities/parent_portal_data.dart';
import '../../domain/repositories/parent_portal_repository.dart';

final parentPortalRepositoryProvider = Provider<ParentPortalRepository>((ref) {
  return ParentPortalRepositoryImpl(client: ref.watch(supabaseClientProvider));
});

final parentPortalDataProvider = FutureProvider.autoDispose.family<ParentPortalData?, String>((ref, token) {
  return ref.watch(parentPortalRepositoryProvider).getPortalData(token);
});

typedef ParentIcLookupParams = ({String parentIc, String? childIc});

final parentPortalDataByIcProvider =
    FutureProvider.autoDispose.family<List<ParentPortalData>, ParentIcLookupParams>((ref, params) {
  return ref.watch(parentPortalRepositoryProvider).getPortalDataByIc(
        parentIc: params.parentIc,
        childIc: params.childIc,
      );
});
