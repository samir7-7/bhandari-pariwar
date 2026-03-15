import 'package:cloud_firestore/cloud_firestore.dart';

class ElderSaying {
  final String id;
  final Map<String, String> name;
  final Map<String, String> title;
  final Map<String, String> saying;
  final String? photoUrl;
  final int order;

  const ElderSaying({
    required this.id,
    required this.name,
    required this.title,
    required this.saying,
    this.photoUrl,
    required this.order,
  });

  String localizedName(String langCode) =>
      name[langCode] ?? name['en'] ?? '';
  String localizedTitle(String langCode) =>
      title[langCode] ?? title['en'] ?? '';
  String localizedSaying(String langCode) =>
      saying[langCode] ?? saying['en'] ?? '';

  factory ElderSaying.fromMap(Map<String, dynamic> map) {
    return ElderSaying(
      id: map['id'] as String? ?? '',
      name: Map<String, String>.from(map['name'] ?? {}),
      title: Map<String, String>.from(map['title'] ?? {}),
      saying: Map<String, String>.from(map['saying'] ?? {}),
      photoUrl: map['photoUrl'] as String?,
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'title': title,
      'saying': saying,
      'order': order,
    };
    if (photoUrl != null) map['photoUrl'] = photoUrl;
    return map;
  }

  ElderSaying copyWith({
    String? id,
    Map<String, String>? name,
    Map<String, String>? title,
    Map<String, String>? saying,
    String? photoUrl,
    int? order,
    bool clearPhotoUrl = false,
  }) {
    return ElderSaying(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      saying: saying ?? this.saying,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      order: order ?? this.order,
    );
  }
}

class ElderSayingsContent {
  final List<ElderSaying> sayings;
  final DateTime updatedAt;

  const ElderSayingsContent({
    required this.sayings,
    required this.updatedAt,
  });

  factory ElderSayingsContent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final list = (data['sayings'] as List<dynamic>?)
            ?.map((e) => ElderSaying.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];
    list.sort((a, b) => a.order.compareTo(b.order));
    return ElderSayingsContent(
      sayings: list,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sayings': sayings.map((s) => s.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
