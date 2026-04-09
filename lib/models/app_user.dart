import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  static const statusPending = 'pending';
  static const statusApproved = 'approved';
  static const statusRejected = 'rejected';

  static const roleUser = 'user';
  static const roleAdmin = 'admin';

  final String uid;
  final String fullName;
  final String contact;
  final String email;
  final String address;
  final String languageCode;
  final String status;
  final String role;
  final bool notificationsEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;
  final DateTime? lastLoginAt;
  final String? approvedBy;
  final String? approvedByEmail;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.contact,
    required this.email,
    required this.address,
    required this.languageCode,
    required this.status,
    required this.role,
    required this.notificationsEnabled,
    this.createdAt,
    this.updatedAt,
    this.approvedAt,
    this.lastLoginAt,
    this.approvedBy,
    this.approvedByEmail,
  });

  bool get isPending => status == statusPending;
  bool get isApproved => status == statusApproved;
  bool get isAdmin => role == roleAdmin;

  factory AppUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AppUser(
      uid: (data['uid'] ?? doc.id).toString(),
      fullName: (data['fullName'] ?? '').toString(),
      contact: (data['contact'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      languageCode: (data['languageCode'] ?? 'en').toString(),
      status: (data['status'] ?? statusPending).toString(),
      role: (data['role'] ?? roleUser).toString(),
      notificationsEnabled: data['notificationsEnabled'] == true,
      createdAt: _asDateTime(data['createdAt']),
      updatedAt: _asDateTime(data['updatedAt']),
      approvedAt: _asDateTime(data['approvedAt']),
      lastLoginAt: _asDateTime(data['lastLoginAt']),
      approvedBy: data['approvedBy']?.toString(),
      approvedByEmail: data['approvedByEmail']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'fullName': fullName,
      'contact': contact,
      'email': email,
      'address': address,
      'languageCode': languageCode,
      'status': status,
      'role': role,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'approvedAt': approvedAt == null ? null : Timestamp.fromDate(approvedAt!),
      'lastLoginAt':
          lastLoginAt == null ? null : Timestamp.fromDate(lastLoginAt!),
      'approvedBy': approvedBy,
      'approvedByEmail': approvedByEmail,
    };
  }

  AppUser copyWith({
    String? fullName,
    String? contact,
    String? email,
    String? address,
    String? languageCode,
    String? status,
    String? role,
    bool? notificationsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
    DateTime? lastLoginAt,
    String? approvedBy,
    String? approvedByEmail,
  }) {
    return AppUser(
      uid: uid,
      fullName: fullName ?? this.fullName,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      address: address ?? this.address,
      languageCode: languageCode ?? this.languageCode,
      status: status ?? this.status,
      role: role ?? this.role,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByEmail: approvedByEmail ?? this.approvedByEmail,
    );
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}
