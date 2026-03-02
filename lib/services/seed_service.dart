import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final seedServiceProvider = Provider<SeedService>((ref) => SeedService());

class SeedService {
  final _membersCollection =
      FirebaseFirestore.instance.collection('members');
  static bool _autoSeedDone = false;

  /// Auto-seeds the database on first launch if it's empty.
  Future<void> autoSeedIfEmpty() async {
    if (_autoSeedDone) return;
    _autoSeedDone = true;

    final snap = await _membersCollection.limit(1).get();
    if (snap.docs.isEmpty) {
      await seedMembersFromAsset();
    }
  }

  Future<int> seedMembersFromAsset() async {
    final jsonString = await rootBundle.loadString('assets/members_data.json');
    final List<dynamic> membersJson = json.decode(jsonString);

    var batch = FirebaseFirestore.instance.batch();
    int count = 0;
    int batchCount = 0;

    for (final memberData in membersJson) {
      final id = memberData['id'] as String;
      final doc = _membersCollection.doc(id);

      final data = <String, dynamic>{
        'name': Map<String, String>.from(memberData['name']),
        'gender': memberData['gender'],
        'isAlive': memberData['isAlive'],
        'parentId': memberData['parentId'],
        'spouseId': memberData['spouseId'],
        'birthOrder': memberData['birthOrder'] ?? 0,
        'birthDate': null,
        'deathDate': null,
        'photoUrl': null,
        'thumbnailUrl': null,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'createdBy': 'seed',
      };

      batch.set(doc, data);
      count++;
      batchCount++;

      // Firestore batches are limited to 500 operations.
      if (batchCount >= 450) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }
    return count;
  }

  Future<int> getMembersCount() async {
    final snap = await _membersCollection.get();
    return snap.docs.length;
  }

  Future<void> clearAllMembers() async {
    final snap = await _membersCollection.get();
    final batch = FirebaseFirestore.instance.batch();
    int count = 0;

    for (final doc in snap.docs) {
      batch.delete(doc.reference);
      count++;

      if (count % 450 == 0) {
        await batch.commit();
      }
    }

    if (count % 450 != 0) {
      await batch.commit();
    }
  }
}
