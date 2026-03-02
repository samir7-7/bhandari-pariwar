import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/models/about_content.dart';
import 'package:bhandari_pariwar/models/committee_member.dart';

final contentServiceProvider =
    Provider<ContentService>((ref) => ContentService());

class ContentService {
  final _collection = FirebaseFirestore.instance.collection('content');

  Future<AboutContent?> getContent(String docId) async {
    final doc = await _collection.doc(docId).get();
    if (!doc.exists) return null;
    return AboutContent.fromFirestore(doc);
  }

  Stream<AboutContent?> watchContent(String docId) {
    return _collection.doc(docId).snapshots().map(
          (doc) => doc.exists ? AboutContent.fromFirestore(doc) : null,
        );
  }

  Future<void> updateContent(String docId, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _collection.doc(docId).set(data, SetOptions(merge: true));
  }

  Future<CommitteeContent?> getCommittee() async {
    final doc = await _collection.doc('committee').get();
    if (!doc.exists) return null;
    return CommitteeContent.fromFirestore(doc);
  }

  Stream<CommitteeContent?> watchCommittee() {
    return _collection.doc('committee').snapshots().map(
          (doc) => doc.exists ? CommitteeContent.fromFirestore(doc) : null,
        );
  }

  Future<void> updateCommittee(CommitteeContent committee) async {
    await _collection.doc('committee').set(committee.toFirestore());
  }
}
