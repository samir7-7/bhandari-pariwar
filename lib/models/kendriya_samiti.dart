import 'package:cloud_firestore/cloud_firestore.dart';

class KendriyaSamitiMember {
  final int serialNumber;
  final Map<String, String> name;
  final Map<String, String> position;
  final String phone;
  final Map<String, String> address;
  final String? photoUrl;

  const KendriyaSamitiMember({
    required this.serialNumber,
    required this.name,
    required this.position,
    required this.phone,
    required this.address,
    this.photoUrl,
  });

  String localizedName(String languageCode) {
    return name[languageCode] ?? name['en'] ?? '';
  }

  String localizedPosition(String languageCode) {
    return position[languageCode] ?? position['en'] ?? '';
  }

  String localizedAddress(String languageCode) {
    return address[languageCode] ?? address['en'] ?? '';
  }

  /// Deterministic key used as the storage sub-directory name for this
  /// member's photo.  Must match the key produced by [_memberPhotoKey] in
  /// the edit screens so that the display screens can resolve photos from
  /// the same directory.
  String get storageKey {
    final nameEn = name['en'] ?? '';
    final nameNe = name['ne'] ?? '';
    final raw = 'sn_${serialNumber}_${nameEn}_$nameNe'.toLowerCase();
    final normalized = raw
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'sn_$serialNumber' : normalized;
  }

  factory KendriyaSamitiMember.fromMap(Map<String, dynamic> map) {
    return KendriyaSamitiMember(
      serialNumber: map['serialNumber'] ?? 0,
      name: Map<String, String>.from(map['name'] ?? {}),
      position: Map<String, String>.from(map['position'] ?? {}),
      phone: map['phone'] ?? '',
      address: Map<String, String>.from(map['address'] ?? {}),
      photoUrl: map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serialNumber': serialNumber,
      'name': name,
      'position': position,
      'phone': phone,
      'address': address,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }

  KendriyaSamitiMember copyWith({
    int? serialNumber,
    Map<String, String>? name,
    Map<String, String>? position,
    String? phone,
    Map<String, String>? address,
    String? photoUrl,
    bool clearPhotoUrl = false,
  }) {
    return KendriyaSamitiMember(
      serialNumber: serialNumber ?? this.serialNumber,
      name: name ?? this.name,
      position: position ?? this.position,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
    );
  }
}

class KendriyaSamitiContent {
  final List<KendriyaSamitiMember> members;
  final DateTime updatedAt;

  const KendriyaSamitiContent({
    required this.members,
    required this.updatedAt,
  });

  factory KendriyaSamitiContent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KendriyaSamitiContent(
      members: (data['members'] as List?)
              ?.map((m) =>
                  KendriyaSamitiMember.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'members': members.map((m) => m.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }
}
