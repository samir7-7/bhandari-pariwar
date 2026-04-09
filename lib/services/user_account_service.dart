import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/config/auth_constants.dart';
import 'package:bhandari_pariwar/models/app_user.dart';

final userAccountServiceProvider =
    Provider<UserAccountService>((ref) => UserAccountService());

class UserAccountService {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection(AuthConstants.userCollection);

  Stream<AppUser?> watchUser(String uid) {
    return _collection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Stream<List<AppUser>> watchPendingRequests() {
    return _collection.where('status', isEqualTo: AppUser.statusPending).snapshots().map(
      (snap) {
        final users = snap.docs.map(AppUser.fromFirestore).toList();
        users.sort((a, b) {
          final aCreated = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bCreated = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aCreated.compareTo(bCreated);
        });
        return users;
      },
    );
  }

  Future<void> createSignupRequest({
    required User user,
    required String fullName,
    required String contact,
    required String address,
    required String languageCode,
    required bool notificationsEnabled,
  }) async {
    final now = FieldValue.serverTimestamp();
    await _collection.doc(user.uid).set({
      'uid': user.uid,
      'fullName': fullName.trim(),
      'contact': contact.trim(),
      'email': (user.email ?? '').trim().toLowerCase(),
      'address': address.trim(),
      'languageCode': languageCode,
      'status': AppUser.statusPending,
      'role': AppUser.roleUser,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': now,
      'updatedAt': now,
      'lastLoginAt': now,
    }, SetOptions(merge: true));
  }

  Future<void> ensureAdminProfile({
    required User user,
    String fullName = 'Admin User',
    required String languageCode,
    required bool notificationsEnabled,
  }) async {
    final now = FieldValue.serverTimestamp();
    await _collection.doc(user.uid).set({
      'uid': user.uid,
      'fullName': fullName.trim().isEmpty ? 'Admin User' : fullName.trim(),
      'contact': '',
      'email': (user.email ?? '').trim().toLowerCase(),
      'address': '',
      'languageCode': languageCode,
      'status': AppUser.statusApproved,
      'role': AppUser.roleAdmin,
      'notificationsEnabled': notificationsEnabled,
      'approvedAt': now,
      'updatedAt': now,
      'lastLoginAt': now,
    }, SetOptions(merge: true));
  }

  Future<void> touchSignedInUser({
    required User user,
    required String languageCode,
    required bool notificationsEnabled,
  }) async {
    await _collection.doc(user.uid).set({
      'email': (user.email ?? '').trim().toLowerCase(),
      'languageCode': languageCode,
      'notificationsEnabled': notificationsEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> approveRequest({
    required String uid,
    required String approvedBy,
    required String approvedByEmail,
  }) async {
    await _collection.doc(uid).set({
      'status': AppUser.statusApproved,
      'updatedAt': FieldValue.serverTimestamp(),
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': approvedBy,
      'approvedByEmail': approvedByEmail,
    }, SetOptions(merge: true));
  }

  Future<void> deleteUserRequest(String uid) async {
    await _collection.doc(uid).delete();
  }

  Future<void> deleteUserRequestAsAdmin(String uid) async {
    await _collection.doc(uid).delete();
  }
}
