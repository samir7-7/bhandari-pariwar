import 'package:cloud_firestore/cloud_firestore.dart';

class Member {
  final String id;
  final Map<String, String> name;
  final String gender;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? photoUrl;
  final String? thumbnailUrl;
  final String? parentId;
  final String? spouseId;
  final int birthOrder;
  final bool isAlive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  const Member({
    required this.id,
    required this.name,
    required this.gender,
    this.birthDate,
    this.deathDate,
    this.photoUrl,
    this.thumbnailUrl,
    this.parentId,
    this.spouseId,
    this.birthOrder = 0,
    this.isAlive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  String localizedName(String languageCode) {
    return name[languageCode] ?? name['en'] ?? name.values.firstOrNull ?? '';
  }

  bool get isRoot => parentId == null;
  bool get hasSpouse => spouseId != null;
  bool get isMale => gender == 'male';

  factory Member.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Member(
      id: doc.id,
      name: Map<String, String>.from(data['name'] ?? {}),
      gender: data['gender'] ?? 'male',
      birthDate: _parseDate(data['birthDate']),
      deathDate: _parseDate(data['deathDate']),
      photoUrl: data['photoUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      parentId: data['parentId'],
      spouseId: data['spouseId'],
      birthOrder: data['birthOrder'] ?? 0,
      isAlive: data['isAlive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'deathDate': deathDate?.toIso8601String(),
      'photoUrl': photoUrl,
      'thumbnailUrl': thumbnailUrl,
      'parentId': parentId,
      'spouseId': spouseId,
      'birthOrder': birthOrder,
      'isAlive': isAlive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'createdBy': createdBy,
    };
  }

  Member copyWith({
    String? id,
    Map<String, String>? name,
    String? gender,
    DateTime? birthDate,
    DateTime? deathDate,
    String? photoUrl,
    String? thumbnailUrl,
    String? parentId,
    String? spouseId,
    int? birthOrder,
    bool? isAlive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      deathDate: deathDate ?? this.deathDate,
      photoUrl: photoUrl ?? this.photoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      parentId: parentId ?? this.parentId,
      spouseId: spouseId ?? this.spouseId,
      birthOrder: birthOrder ?? this.birthOrder,
      isAlive: isAlive ?? this.isAlive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
