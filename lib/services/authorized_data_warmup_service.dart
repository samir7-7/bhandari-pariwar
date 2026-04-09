import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authorizedDataWarmupServiceProvider =
    Provider<AuthorizedDataWarmupService>(
  (ref) => AuthorizedDataWarmupService(),
);

class AuthorizedDataWarmupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> waitUntilReady() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.getIdToken(true);
    } catch (_) {}

    Object? lastError;

    for (var attempt = 0; attempt < 6; attempt++) {
      try {
        await Future.wait([
          _firestore.collection('members').limit(1).get(),
          _firestore.collection('notices').limit(1).get(),
          _firestore.collection('content').limit(1).get(),
        ]);
        return;
      } catch (error) {
        lastError = error;
        if (!_shouldRetry(error) || attempt == 5) {
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 350 * (attempt + 1)));
      }
    }

    if (lastError != null) {
      throw lastError;
    }
  }

  bool _shouldRetry(Object error) {
    if (error is! FirebaseException) return false;

    return error.code == 'permission-denied' ||
        error.code == 'unauthenticated' ||
        error.code == 'unavailable' ||
        error.code == 'aborted' ||
        error.code == 'failed-precondition';
  }
}
