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
  final List<String> spouseIds;
  final int birthOrder;
  final int? sourceOrder;
  final bool isAlive;
  final String? birthDateBs;
  final DateTime? birthDateAd;
  final Map<String, String?> birthPlace;
  final Map<String, String?> currentAddress;
  final Map<String, String?> permanentAddress;
  final Map<String, String?> fatherName;
  final Map<String, String?> motherName;
  final String? mobilePrimary;
  final String? mobileSecondary;
  final String? email;
  final Map<String, String?> educationOrProfession;
  final String? bloodGroup;
  final int? familyCount;
  final int? sonsCount;
  final int? daughtersCount;
  final Map<String, String?> notes;
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
    this.spouseIds = const [],
    this.birthOrder = 0,
    this.sourceOrder,
    this.isAlive = true,
    this.birthDateBs,
    this.birthDateAd,
    this.birthPlace = const {},
    this.currentAddress = const {},
    this.permanentAddress = const {},
    this.fatherName = const {},
    this.motherName = const {},
    this.mobilePrimary,
    this.mobileSecondary,
    this.email,
    this.educationOrProfession = const {},
    this.bloodGroup,
    this.familyCount,
    this.sonsCount,
    this.daughtersCount,
    this.notes = const {},
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  String localizedName(String languageCode) {
    return name[languageCode] ?? name['en'] ?? name.values.firstOrNull ?? '';
  }

  String localizedBirthPlace(String languageCode) {
    return birthPlace[languageCode] ?? birthPlace['en'] ?? '';
  }

  String localizedCurrentAddress(String languageCode) {
    return currentAddress[languageCode] ?? currentAddress['en'] ?? '';
  }

  String localizedPermanentAddress(String languageCode) {
    return permanentAddress[languageCode] ?? permanentAddress['en'] ?? '';
  }

  String localizedFatherName(String languageCode) {
    return fatherName[languageCode] ?? fatherName['en'] ?? '';
  }

  String localizedMotherName(String languageCode) {
    return motherName[languageCode] ?? motherName['en'] ?? '';
  }

  String localizedEducationOrProfession(String languageCode) {
    return educationOrProfession[languageCode] ??
        educationOrProfession['en'] ??
        '';
  }

  String localizedNote(String languageCode) {
    return notes[languageCode] ?? notes['en'] ?? '';
  }

  List<String> get allSpouseIds {
    final ids = <String>[];
    if (spouseId != null && spouseId!.isNotEmpty) {
      ids.add(spouseId!);
    }
    for (final id in spouseIds) {
      if (id.isNotEmpty && !ids.contains(id)) {
        ids.add(id);
      }
    }
    return ids;
  }

  String? get primarySpouseId {
    if (spouseId != null && spouseId!.isNotEmpty) {
      return spouseId;
    }
    return spouseIds.firstOrNull;
  }

  bool get isRoot => parentId == null;
  bool get hasSpouse => allSpouseIds.isNotEmpty;
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
      spouseIds: _parseStringList(data['spouseIds'], data['spouseId']),
      birthOrder: data['birthOrder'] ?? 0,
      sourceOrder: _parseInt(data['sourceOrder']),
      isAlive: data['isAlive'] is bool ? data['isAlive'] : true,
      birthDateBs: data['birthDateBs'] as String?,
      birthDateAd: _parseDate(data['birthDateAd']),
      birthPlace: _toNullableStringMap(data['birthPlace']),
      currentAddress: _toNullableStringMap(data['currentAddress']),
      permanentAddress: _toNullableStringMap(data['permanentAddress']),
      fatherName: _toNullableStringMap(data['fatherName']),
      motherName: _toNullableStringMap(data['motherName']),
      mobilePrimary: data['mobilePrimary'] as String?,
      mobileSecondary: data['mobileSecondary'] as String?,
      email: data['email'] as String?,
      educationOrProfession:
          _toNullableStringMap(data['educationOrProfession']),
      bloodGroup: data['bloodGroup'] as String?,
      familyCount: _parseInt(data['familyCount']),
      sonsCount: _parseInt(data['sonsCount']),
      daughtersCount: _parseInt(data['daughtersCount']),
      notes: _toNullableStringMap(data['notes']),
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
      'spouseIds': allSpouseIds,
      'birthOrder': birthOrder,
      'sourceOrder': sourceOrder,
      'isAlive': isAlive,
      'birthDateBs': birthDateBs,
      'birthDateAd': birthDateAd?.toIso8601String(),
      'birthPlace': birthPlace,
      'currentAddress': currentAddress,
      'permanentAddress': permanentAddress,
      'fatherName': fatherName,
      'motherName': motherName,
      'mobilePrimary': mobilePrimary,
      'mobileSecondary': mobileSecondary,
      'email': email,
      'educationOrProfession': educationOrProfession,
      'bloodGroup': bloodGroup,
      'familyCount': familyCount,
      'sonsCount': sonsCount,
      'daughtersCount': daughtersCount,
      'notes': notes,
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
    List<String>? spouseIds,
    int? birthOrder,
    int? sourceOrder,
    bool? isAlive,
    String? birthDateBs,
    DateTime? birthDateAd,
    Map<String, String?>? birthPlace,
    Map<String, String?>? currentAddress,
    Map<String, String?>? permanentAddress,
    Map<String, String?>? fatherName,
    Map<String, String?>? motherName,
    String? mobilePrimary,
    String? mobileSecondary,
    String? email,
    Map<String, String?>? educationOrProfession,
    String? bloodGroup,
    int? familyCount,
    int? sonsCount,
    int? daughtersCount,
    Map<String, String?>? notes,
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
      spouseIds: spouseIds ?? this.spouseIds,
      birthOrder: birthOrder ?? this.birthOrder,
      sourceOrder: sourceOrder ?? this.sourceOrder,
      isAlive: isAlive ?? this.isAlive,
      birthDateBs: birthDateBs ?? this.birthDateBs,
      birthDateAd: birthDateAd ?? this.birthDateAd,
      birthPlace: birthPlace ?? this.birthPlace,
      currentAddress: currentAddress ?? this.currentAddress,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      mobilePrimary: mobilePrimary ?? this.mobilePrimary,
      mobileSecondary: mobileSecondary ?? this.mobileSecondary,
      email: email ?? this.email,
      educationOrProfession:
          educationOrProfession ?? this.educationOrProfession,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      familyCount: familyCount ?? this.familyCount,
      sonsCount: sonsCount ?? this.sonsCount,
      daughtersCount: daughtersCount ?? this.daughtersCount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  static Map<String, String?> _toNullableStringMap(dynamic value) {
    if (value is Map) {
      return value.map(
        (k, v) => MapEntry(k.toString(), v?.toString()),
      );
    }
    return {};
  }

  static List<String> _parseStringList(dynamic value, dynamic fallbackSingle) {
    if (value is List) {
      final ids = value
          .where((item) => item != null)
          .map((item) => item.toString())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      if (ids.isNotEmpty) {
        return ids;
      }
    }

    if (fallbackSingle is String && fallbackSingle.isNotEmpty) {
      return [fallbackSingle];
    }

    return const [];
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
