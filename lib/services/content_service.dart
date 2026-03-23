import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/models/about_content.dart';
import 'package:bhandari_pariwar/models/committee_member.dart';
import 'package:bhandari_pariwar/models/elder_saying.dart';
import 'package:bhandari_pariwar/models/kendriya_samiti.dart';

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

  // --- Kendriya Samiti ---

  Stream<KendriyaSamitiContent?> watchKendriyaSamiti() {
    return _collection.doc('kendriya_samiti').snapshots().map(
          (doc) =>
              doc.exists ? KendriyaSamitiContent.fromFirestore(doc) : null,
        );
  }

  Future<KendriyaSamitiContent?> getKendriyaSamiti() async {
    final doc = await _collection.doc('kendriya_samiti').get();
    if (!doc.exists) return null;
    return KendriyaSamitiContent.fromFirestore(doc);
  }

  Future<void> updateKendriyaSamiti(KendriyaSamitiContent content) async {
    await _collection.doc('kendriya_samiti').set(content.toFirestore());
  }

  // --- Bidesh Samiti ---

  Stream<KendriyaSamitiContent?> watchBideshSamiti() {
    return _collection.doc('bidesh_samiti').snapshots().map(
          (doc) =>
              doc.exists ? KendriyaSamitiContent.fromFirestore(doc) : null,
        );
  }

  Future<KendriyaSamitiContent?> getBideshSamiti() async {
    final doc = await _collection.doc('bidesh_samiti').get();
    if (!doc.exists) return null;
    return KendriyaSamitiContent.fromFirestore(doc);
  }

  Future<void> updateBideshSamiti(KendriyaSamitiContent content) async {
    await _collection.doc('bidesh_samiti').set(content.toFirestore());
  }

  // --- Elder Sayings ---

  Stream<ElderSayingsContent?> watchElderSayings() {
    return _collection.doc('elder_sayings').snapshots().map(
          (doc) =>
              doc.exists ? ElderSayingsContent.fromFirestore(doc) : null,
        );
  }

  Future<ElderSayingsContent?> getElderSayings() async {
    final doc = await _collection.doc('elder_sayings').get();
    if (!doc.exists) return null;
    return ElderSayingsContent.fromFirestore(doc);
  }

  Future<void> updateElderSayings(ElderSayingsContent content) async {
    await _collection.doc('elder_sayings').set(content.toFirestore());
  }

  // --- Memorial Sayings ---

  Stream<ElderSayingsContent?> watchMemorialSayings() {
    return _collection.doc('memorial_sayings').snapshots().map(
          (doc) =>
              doc.exists ? ElderSayingsContent.fromFirestore(doc) : null,
        );
  }

  Future<ElderSayingsContent?> getMemorialSayings() async {
    final doc = await _collection.doc('memorial_sayings').get();
    if (!doc.exists) return null;
    return ElderSayingsContent.fromFirestore(doc);
  }

  Future<void> updateMemorialSayings(ElderSayingsContent content) async {
    await _collection.doc('memorial_sayings').set(content.toFirestore());
  }
}
