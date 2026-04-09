import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/config/auth_constants.dart';
import 'package:bhandari_pariwar/models/app_user.dart';
import 'package:bhandari_pariwar/services/auth_service.dart';
import 'package:bhandari_pariwar/services/user_account_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentAppUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return Stream.value(null);
  }

  final userAccountService = ref.watch(userAccountServiceProvider);
  return userAccountService.watchUser(user.uid);
});

class AuthSessionState {
  const AuthSessionState({
    required this.firebaseUser,
    required this.appUser,
  });

  final User? firebaseUser;
  final AppUser? appUser;

  bool get isSignedIn => firebaseUser != null;

  bool get isAdmin =>
      AuthConstants.isAdminEmail(firebaseUser?.email) || appUser?.isAdmin == true;

  bool get hasApprovedAccess =>
      firebaseUser != null && (isAdmin || appUser?.isApproved == true);

  bool get isPendingApproval =>
      firebaseUser != null &&
      !isAdmin &&
      appUser != null &&
      appUser!.isPending;

  bool get isMissingProfile =>
      firebaseUser != null && !isAdmin && appUser == null;
}

final authSessionProvider = Provider<AsyncValue<AuthSessionState>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (firebaseUser) {
      if (firebaseUser == null) {
        return const AsyncValue.data(
          AuthSessionState(firebaseUser: null, appUser: null),
        );
      }

      final appUserState = ref.watch(currentAppUserProvider);
      return appUserState.when(
        data: (appUser) => AsyncValue.data(
          AuthSessionState(firebaseUser: firebaseUser, appUser: appUser),
        ),
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

final hasApprovedAccessProvider = Provider<bool>((ref) {
  final session = ref.watch(authSessionProvider);
  return session.valueOrNull?.hasApprovedAccess ?? false;
});

final isSignedInProvider = Provider<bool>((ref) {
  final session = ref.watch(authSessionProvider);
  return session.valueOrNull?.isSignedIn ?? false;
});

final isPendingApprovalProvider = Provider<bool>((ref) {
  final session = ref.watch(authSessionProvider);
  return session.valueOrNull?.isPendingApproval ?? false;
});

final isAdminProvider = Provider<bool>((ref) {
  final session = ref.watch(authSessionProvider);
  return session.valueOrNull?.isAdmin ?? false;
});
