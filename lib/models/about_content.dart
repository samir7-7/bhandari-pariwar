import 'package:cloud_firestore/cloud_firestore.dart';

class AboutContent {
  final String id;
  final Map<String, String> title;
  final Map<String, String>? body;
  final List<ContentSection>? sections;
  final DateTime updatedAt;
  final String? updatedBy;

  const AboutContent({
    required this.id,
    required this.title,
    this.body,
    this.sections,
    required this.updatedAt,
    this.updatedBy,
  });

  String localizedTitle(String languageCode) {
    return title[languageCode] ?? title['en'] ?? '';
  }

  String localizedBody(String languageCode) {
    if (body == null) return '';
    return body![languageCode] ?? body!['en'] ?? '';
  }

  factory AboutContent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AboutContent(
      id: doc.id,
      title: Map<String, String>.from(data['title'] ?? {}),
      body: data['body'] != null
          ? Map<String, String>.from(data['body'])
          : null,
      sections: data['sections'] != null
          ? (data['sections'] as List)
              .map((s) => ContentSection.fromMap(s as Map<String, dynamic>))
              .toList()
          : null,
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: data['updatedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      if (body != null) 'body': body,
      if (sections != null)
        'sections': sections!.map((s) => s.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'updatedBy': updatedBy,
    };
  }
}

class ContentSection {
  final Map<String, String> heading;
  final Map<String, String> body;

  const ContentSection({
    required this.heading,
    required this.body,
  });

  String localizedHeading(String languageCode) {
    return heading[languageCode] ?? heading['en'] ?? '';
  }

  String localizedBody(String languageCode) {
    return body[languageCode] ?? body['en'] ?? '';
  }

  factory ContentSection.fromMap(Map<String, dynamic> map) {
    return ContentSection(
      heading: Map<String, String>.from(map['heading'] ?? {}),
      body: Map<String, String>.from(map['body'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'heading': heading,
      'body': body,
    };
  }
}
