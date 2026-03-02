import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String id;
  final Map<String, String> title;
  final Map<String, String> body;
  final String? imageUrl;
  final DateTime publishedAt;
  final String createdBy;
  final bool notifyUsers;

  const Notice({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.publishedAt,
    required this.createdBy,
    this.notifyUsers = true,
  });

  String localizedTitle(String languageCode) {
    return title[languageCode] ?? title['en'] ?? title.values.firstOrNull ?? '';
  }

  String localizedBody(String languageCode) {
    return body[languageCode] ?? body['en'] ?? body.values.firstOrNull ?? '';
  }

  factory Notice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Notice(
      id: doc.id,
      title: Map<String, String>.from(data['title'] ?? {}),
      body: Map<String, String>.from(data['body'] ?? {}),
      imageUrl: data['imageUrl'],
      publishedAt:
          (data['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      notifyUsers: data['notifyUsers'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'createdBy': createdBy,
      'notifyUsers': notifyUsers,
    };
  }
}
