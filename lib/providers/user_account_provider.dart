import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/models/app_user.dart';
import 'package:bhandari_pariwar/services/user_account_service.dart';

final pendingUserRequestsProvider = StreamProvider<List<AppUser>>((ref) {
  final service = ref.watch(userAccountServiceProvider);
  return service.watchPendingRequests();
});
