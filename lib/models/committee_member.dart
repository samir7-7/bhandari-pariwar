import 'package:cloud_firestore/cloud_firestore.dart';

class CommitteeMember {
  final String id;
  final Map<String, String> name;
  final Map<String, String> role;
  final String? term;
  final Map<String, String>? bio;
  final String? photoUrl;

  const CommitteeMember({
    required this.id,
    required this.name,
    required this.role,
    this.term,
    this.bio,
    this.photoUrl,
  });

  String localizedName(String languageCode) {
    return name[languageCode] ?? name['en'] ?? '';
  }

  String localizedRole(String languageCode) {
    return role[languageCode] ?? role['en'] ?? '';
  }

  String localizedBio(String languageCode) {
    if (bio == null) return '';
    return bio![languageCode] ?? bio!['en'] ?? '';
  }

  factory CommitteeMember.fromMap(Map<String, dynamic> map) {
    return CommitteeMember(
      id: map['id'] ?? '',
      name: Map<String, String>.from(map['name'] ?? {}),
      role: Map<String, String>.from(map['role'] ?? {}),
      term: map['term'],
      bio: map['bio'] != null
          ? Map<String, String>.from(map['bio'])
          : null,
      photoUrl: map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'term': term,
      if (bio != null) 'bio': bio,
      'photoUrl': photoUrl,
    };
  }
}

class CommitteeContent {
  final List<CommitteeMember> members;
  final DateTime updatedAt;

  const CommitteeContent({
    required this.members,
    required this.updatedAt,
  });

  factory CommitteeContent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommitteeContent(
      members: (data['members'] as List?)
              ?.map((m) =>
                  CommitteeMember.fromMap(m as Map<String, dynamic>))
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
