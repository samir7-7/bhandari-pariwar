import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/config/auth_constants.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';
import 'package:bhandari_pariwar/services/notification_service.dart';
import 'package:bhandari_pariwar/services/user_account_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    userAccountService: ref.watch(userAccountServiceProvider),
    settingsService: ref.watch(settingsServiceProvider),
  );
});

class AuthService {
  AuthService({
    required UserAccountService userAccountService,
    required SettingsService settingsService,
  })  : _userAccountService = userAccountService,
        _settingsService = settingsService;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserAccountService _userAccountService;
  final SettingsService _settingsService;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = result.user;
    if (user != null) {
      await ensureCurrentUserProfile();
      await NotificationService.syncCurrentUserToken();
    }
    return user;
  }

  Future<User?> signUp({
    required String fullName,
    required String contact,
    required String email,
    required String address,
    required String password,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = result.user;
    if (user == null) return null;

    final languageCode = await _settingsService.getLanguageCode();
    final notificationsEnabled =
        await _settingsService.getNotificationsEnabled();

    await _userAccountService.createSignupRequest(
      user: user,
      fullName: fullName,
      contact: contact,
      address: address,
      languageCode: languageCode,
      notificationsEnabled: notificationsEnabled,
    );
    await NotificationService.syncCurrentUserToken();
    return user;
  }

  Future<void> ensureCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final languageCode = await _settingsService.getLanguageCode();
    final notificationsEnabled =
        await _settingsService.getNotificationsEnabled();

    if (AuthConstants.isAdminEmail(user.email)) {
      final fallbackName = user.email?.split('@').first ?? 'Admin User';
      await _userAccountService.ensureAdminProfile(
        user: user,
        fullName: fallbackName,
        languageCode: languageCode,
        notificationsEnabled: notificationsEnabled,
      );
      return;
    }

    final existing = await _userAccountService.getUser(user.uid);
    if (existing != null) {
      await _userAccountService.touchSignedInUser(
        user: user,
        languageCode: languageCode,
        notificationsEnabled: notificationsEnabled,
      );
    }
  }

  Future<void> signOut() async {
    await NotificationService.removeCurrentUserToken();
    await _auth.signOut();
  }

  Future<void> deleteCurrentUserRequest({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final trimmedPassword = password?.trim() ?? '';
    if (trimmedPassword.isNotEmpty && user.email != null) {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: user.email!,
          password: trimmedPassword,
        ),
      );
    }

    await NotificationService.removeCurrentUserToken();
    await _userAccountService.deleteUserRequest(user.uid);
    await user.delete();
    await _auth.signOut();
  }
}
