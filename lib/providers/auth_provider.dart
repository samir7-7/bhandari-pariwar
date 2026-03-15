import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/services/auth_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Returns true only for users who signed in with email+password
/// (non-anonymous). Anonymous sign-in is used only for Firestore seed
/// write access and must not grant admin privileges.
final isAdminProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  // Anonymous users are signed in for seeding purposes only — they are NOT admins.
  return user != null && !user.isAnonymous;
});
