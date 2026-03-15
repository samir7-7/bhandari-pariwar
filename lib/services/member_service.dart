import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/models/member.dart';

final memberServiceProvider =
    Provider<MemberService>((ref) => MemberService());

class MemberService {
  final _collection = FirebaseFirestore.instance.collection('members');

  Stream<List<Member>> watchAllMembers() {
    return _collection.snapshots().map(
          (snap) => snap.docs.map((doc) => Member.fromFirestore(doc)).toList(),
        );
  }

  Future<List<Member>> getAllMembers() async {
    final snap = await _collection.get();
    return snap.docs.map((doc) => Member.fromFirestore(doc)).toList();
  }

  Future<Member?> getMember(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Member.fromFirestore(doc);
  }

  Future<String> addMember(Member member) async {
    final doc = await _collection.add(member.toFirestore());
    return doc.id;
  }

  Future<void> updateMember(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _collection.doc(id).update(data);
  }

  Future<void> deleteMember(String id) async {
    await _collection.doc(id).delete();
  }

  Future<void> setSpouseLink(String memberId, String spouseId) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_collection.doc(memberId), {
      'spouseId': spouseId,
      'spouseIds': FieldValue.arrayUnion([spouseId]),
    });
    batch.update(_collection.doc(spouseId), {
      'spouseId': memberId,
      'spouseIds': FieldValue.arrayUnion([memberId]),
    });
    await batch.commit();
  }
}
