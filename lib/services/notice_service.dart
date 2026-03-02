import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/models/notice.dart';

final noticeServiceProvider =
    Provider<NoticeService>((ref) => NoticeService());

class NoticeService {
  final _collection = FirebaseFirestore.instance.collection('notices');

  Stream<List<Notice>> watchAllNotices() {
    return _collection
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Notice.fromFirestore(doc)).toList(),
        );
  }

  Future<Notice?> getNotice(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Notice.fromFirestore(doc);
  }

  Future<String> addNotice(Notice notice) async {
    final doc = await _collection.add(notice.toFirestore());
    return doc.id;
  }

  Future<void> updateNotice(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }

  Future<void> deleteNotice(String id) async {
    await _collection.doc(id).delete();
  }
}
