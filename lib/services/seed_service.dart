import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bhandari_pariwar/models/kendriya_samiti.dart';
import 'package:bhandari_pariwar/models/elder_saying.dart';
import 'package:bhandari_pariwar/models/committee_member.dart';

final seedServiceProvider = Provider<SeedService>((ref) => SeedService());

class _MembersAssetPayload {
  final String assetPath;
  final String jsonString;
  final List<dynamic> members;

  const _MembersAssetPayload({
    required this.assetPath,
    required this.jsonString,
    required this.members,
  });
}

class SeedService {
  final _membersCollection =
      FirebaseFirestore.instance.collection('members');
  static bool _autoSeedDone = false;


  Future<void> _ensureFirebaseAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }

  /// Auto-seeds the database on first launch if it's empty.
  Future<void> autoSeedIfEmpty() async {
    if (_autoSeedDone) return;
    _autoSeedDone = true;

    final snap = await _membersCollection.limit(1).get();
    if (snap.docs.isEmpty) {
      await seedMembersFromAsset();
    }


    // Auto-seed kendriya samiti if empty
    await seedKendriyaSamitiIfEmpty();

    // Auto-seed bidesh samiti if empty
    await seedBideshSamitiIfEmpty();

    // Auto-seed committee if empty
    await seedCommitteeIfEmpty();

    // Auto-seed elder sayings if empty
    await seedElderSayingsIfEmpty();
  }

  Future<int> seedMembersFromAsset({bool replaceExisting = false}) async {
    await _ensureFirebaseAuth();

    final payload = await _loadMembersAssetPayload();

    if (replaceExisting) {
      await clearAllMembers();
    }

    final jsonString = payload.jsonString;
    final List<dynamic> membersJson = payload.members;

    // Fetch existing IDs to avoid overwriting them
    final existingSnap = await _membersCollection.get();
    final existingIds = existingSnap.docs.map((d) => d.id).toSet();

    var batch = FirebaseFirestore.instance.batch();
    int count = 0;
    int batchCount = 0;
    int sourceOrder = 0;

    for (final memberData in membersJson) {
      final id = memberData['id'] as String;
      
      sourceOrder++;

      // If we aren't replacing existing, and the member already exists, skip it.
      if (!replaceExisting && existingIds.contains(id)) {
        continue;
      }

      final doc = _membersCollection.doc(id);

      final birthDate = _parseDate(memberData['birthDate']);
      final deathDate = _parseDate(memberData['deathDate']);
      final birthDateAd = _parseDate(memberData['birthDateAd']);

      final data = <String, dynamic>{
        'name': Map<String, String>.from(memberData['name']),
        'gender': memberData['gender'],
        'isAlive': memberData['isAlive'],
        'parentId': memberData['parentId'],
        'spouseId': memberData['spouseId'],
        'spouseIds': _parseStringList(memberData['spouseIds'], memberData['spouseId']),
        'birthOrder': memberData['birthOrder'] ?? 0,
        'sourceOrder': sourceOrder,
        'birthDate': birthDate,
        'deathDate': deathDate,
        'birthDateBs': memberData['birthDateBs'],
        'birthDateAd': birthDateAd,
        'birthPlace': _asLocalizedNullableMap(memberData['birthPlace']),
        'currentAddress': _asLocalizedNullableMap(memberData['currentAddress']),
        'permanentAddress': _asLocalizedNullableMap(memberData['permanentAddress']),
        'fatherName': _asLocalizedNullableMap(memberData['fatherName']),
        'motherName': _asLocalizedNullableMap(memberData['motherName']),
        'mobilePrimary': memberData['mobilePrimary'],
        'mobileSecondary': memberData['mobileSecondary'],
        'email': memberData['email'],
        'educationOrProfession': _asLocalizedNullableMap(memberData['educationOrProfession']),
        'bloodGroup': memberData['bloodGroup'],
        'familyCount': memberData['familyCount'],
        'sonsCount': memberData['sonsCount'],
        'daughtersCount': memberData['daughtersCount'],
        'notes': _asLocalizedNullableMap(memberData['notes']),
        'photoUrl': memberData['photoUrl'],
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

  Future<String> _computeCurrentMembersAssetChecksum() async {
    final payload = await _loadMembersAssetPayload();
    return _checksumOf(payload.jsonString);
  }

  Future<bool> _isMembersCollectionInSyncWithAsset() async {
    final payload = await _loadMembersAssetPayload();
    final membersJson = payload.members;
    final assetIds = membersJson
        .map((m) => (m as Map<String, dynamic>)['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    final snap = await _membersCollection.get();
    final firestoreIds = snap.docs.map((doc) => doc.id).toSet();

    if (assetIds.length != firestoreIds.length) {
      return false;
    }

    for (final id in assetIds) {
      if (!firestoreIds.contains(id)) {
        return false;
      }
    }

    return true;
  }

  String _checksumOf(String input) {
    // Deterministic FNV-1a 32-bit checksum; good enough for change detection.
    const int fnvPrime = 0x01000193;
    int hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xffffffff;
    }
    return hash.toRadixString(16);
  }

  Future<_MembersAssetPayload> _loadMembersAssetPayload() async {
    const candidates = <String>[
      'assets/members_data_new.json',
      'assets/members_data.json',
    ];

    // First pass: prefer a parseable, non-empty members list.
    for (final assetPath in candidates) {
      final payload = await _tryLoadMembersAsset(assetPath);
      if (payload != null && payload.members.isNotEmpty) {
        return payload;
      }
    }

    // Second pass: return first parseable file even if empty.
    for (final assetPath in candidates) {
      final payload = await _tryLoadMembersAsset(assetPath);
      if (payload != null) {
        return payload;
      }
    }

    throw const FormatException(
      'No valid members seed asset found. Checked assets/members_data_new.json and assets/members_data.json.',
    );
  }

  Future<_MembersAssetPayload?> _tryLoadMembersAsset(String assetPath) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final decoded = json.decode(jsonString);
      final members = _extractMembers(decoded, assetPath: assetPath);
      return _MembersAssetPayload(
        assetPath: assetPath,
        jsonString: jsonString,
        members: members,
      );
    } catch (_) {
      return null;
    }
  }

  List<dynamic> _extractMembers(dynamic decoded, {String? assetPath}) {
    if (decoded is List<dynamic>) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      final members = decoded['members'];
      if (members is List<dynamic>) {
        return members;
      }
    }
    throw FormatException(
      'Invalid members asset format${assetPath != null ? ' in $assetPath' : ''}. Expected either an array or an object containing a members array.',
    );
  }

  Timestamp? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value.trim());
      if (parsed != null) {
        return Timestamp.fromDate(parsed);
      }
    }
    return null;
  }

  Map<String, String?> _asLocalizedNullableMap(dynamic value) {
    if (value is Map) {
      return value.map(
        (k, v) => MapEntry(k.toString(), v?.toString()),
      );
    }
    return const {};
  }

  List<String> _parseStringList(dynamic value, dynamic fallbackSingle) {
    if (value is List) {
      return value
          .where((item) => item != null)
          .map((item) => item.toString())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
    }
    if (fallbackSingle is String && fallbackSingle.isNotEmpty) {
      return [fallbackSingle];
    }
    return const [];
  }

  Future<int> getMembersCount() async {
    final snap = await _membersCollection.get();
    return snap.docs.length;
  }

  Future<void> clearAllMembers() async {
    final snap = await _membersCollection.get();
    var batch = FirebaseFirestore.instance.batch();
    int batchCount = 0;

    for (final doc in snap.docs) {
      batch.delete(doc.reference);
      batchCount++;

      if (batchCount >= 450) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }
  }

  /// Seeds the Kendriya Samiti data if the document doesn't exist.
  Future<void> seedKendriyaSamitiIfEmpty() async {
    final contentCollection =
        FirebaseFirestore.instance.collection('content');
    final doc = await contentCollection.doc('kendriya_samiti').get();
    if (doc.exists) return;

    final content = KendriyaSamitiContent(
      members: _kendriyaSamitiData,
      updatedAt: DateTime.now(),
    );
    await contentCollection
        .doc('kendriya_samiti')
        .set(content.toFirestore());
  }

  static final List<KendriyaSamitiMember> _kendriyaSamitiData = [
    const KendriyaSamitiMember(
      serialNumber: 1,
      name: {'en': 'Krishna Prasad Bhandari Ghairali', 'ne': 'कृष्णप्रसाद भण्डारी घैराली'},
      position: {'en': 'President', 'ne': 'अध्यक्ष'},
      phone: '9829026662',
      address: {'en': 'Tilottama / Rupandehi', 'ne': 'तिलोत्तमा / रुपन्देही'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 2,
      name: {'en': 'Dhanshyam Bhandari', 'ne': 'धनश्याम भण्डारी'},
      position: {'en': 'Senior Vice President', 'ne': 'वरिष्ठ उपाध्यक्ष'},
      phone: '9823099337',
      address: {'en': 'Ward 11 / Golpark–5', 'ne': '११ / गोलपार्क–५'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 3,
      name: {'en': 'Keshwar Bhandari', 'ne': 'केशवर भण्डारी'},
      position: {'en': 'Vice President', 'ne': 'उपाध्यक्ष'},
      phone: '9823445423',
      address: {'en': 'Butwal–6', 'ne': 'बुटवल–६'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 4,
      name: {'en': 'Hari Prasad Bhandari', 'ne': 'हरिप्रसाद भण्डारी'},
      position: {'en': 'Vice President', 'ne': 'उपाध्यक्ष'},
      phone: '982268920',
      address: {'en': 'Tilottama–7', 'ne': 'तिलोत्तमा–७'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 5,
      name: {'en': 'Ranan Bhandari', 'ne': 'राणण भण्डारी'},
      position: {'en': 'Vice President', 'ne': 'उपाध्यक्ष'},
      phone: '982075666',
      address: {'en': 'Tilottama–8', 'ne': 'तिलोत्तमा–८'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 6,
      name: {'en': 'Dev Raj Bhandari', 'ne': 'देवराज भण्डारी'},
      position: {'en': 'Vice President', 'ne': 'उपाध्यक्ष'},
      phone: '982806547',
      address: {'en': 'Bhairahawa', 'ne': 'प.भा.–भैरहवा'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 7,
      name: {'en': 'Indra Lal Bhandari', 'ne': 'इन्द्रलाल भण्डारी'},
      position: {'en': 'Vice President', 'ne': 'उपाध्यक्ष'},
      phone: '982466855',
      address: {'en': 'Bhairahawa', 'ne': 'भैरहवा'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 8,
      name: {'en': 'Ganga Ram Bhandari', 'ne': 'गंगाराम भण्डारी'},
      position: {'en': 'Vice President', 'ne': 'उपाध्यक्ष'},
      phone: '982328991',
      address: {'en': 'Rupandehi–5', 'ne': 'रुपन्देही–५'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 9,
      name: {'en': 'Kamala Devi Ghimire Bhandari', 'ne': 'कमलादेवी घिमिरे भण्डारी'},
      position: {'en': 'Vice President', 'ne': 'उपाध्यक्ष'},
      phone: '982548754',
      address: {'en': 'Arghakhanchi', 'ne': 'अर्घाखाँची'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 10,
      name: {'en': 'Jai Prasad Bhandari', 'ne': 'जयप्रसाद भण्डारी'},
      position: {'en': 'General Secretary', 'ne': 'महासचिव'},
      phone: '982669608',
      address: {'en': 'Butwal–2', 'ne': 'बुटवल–२'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 11,
      name: {'en': 'Anand Kumar Bhandari', 'ne': 'आनन्दकुमार भण्डारी'},
      position: {'en': 'Secretary', 'ne': 'सचिव'},
      phone: '982433593',
      address: {'en': 'Siddharthanagar–8', 'ne': 'सिद्धार्थनगर–८'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 12,
      name: {'en': 'Rudranath Bhandari', 'ne': 'रुद्रनाथ भण्डारी'},
      position: {'en': 'Joint Secretary', 'ne': 'सह सचिव'},
      phone: '982431691',
      address: {'en': 'Kamal–8 Jhapa', 'ne': 'कमल–८ झापा'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 13,
      name: {'en': 'Chetana Niraula Bhandari', 'ne': 'चेतना निरौला भण्डारी'},
      position: {'en': 'Treasurer', 'ne': 'कोषाध्यक्ष'},
      phone: '982463807',
      address: {'en': 'Butwal–12', 'ne': 'बुटवल–१२'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 14,
      name: {'en': 'Tekendra Bhandari', 'ne': 'टेकन्द्र भण्डारी'},
      position: {'en': 'Assistant Treasurer', 'ne': 'सहकोषाध्यक्ष'},
      phone: '982583632',
      address: {'en': 'Butwal', 'ne': 'बुटवल'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 15,
      name: {'en': 'Pushpa Lal Bhandari', 'ne': 'पुष्पलाल भण्डारी'},
      position: {'en': 'Member', 'ne': 'सदस्य'},
      phone: '982511473',
      address: {'en': 'Tilottama–11', 'ne': 'तिलोत्तमा–११'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 16,
      name: {'en': 'Hari Prasad Bhandari', 'ne': 'हरिप्रसाद भण्डारी'},
      position: {'en': 'Member', 'ne': 'सदस्य'},
      phone: '982354605',
      address: {'en': 'Lekgaon – Argha', 'ne': 'लेकगाउँ–अर्घा'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 17,
      name: {'en': 'Durga Devi Gautam Bhandari', 'ne': 'दुर्गादेवी गौतम भण्डारी'},
      position: {'en': 'Member', 'ne': 'सदस्य'},
      phone: '982565552',
      address: {'en': 'Lekgaon – Argha', 'ne': 'लेकगाउँ–अर्घा'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 18,
      name: {'en': 'Kalpana Bhandari', 'ne': 'कल्पना भण्डारी'},
      position: {'en': 'Member', 'ne': 'सदस्य'},
      phone: '982620086',
      address: {'en': 'Tilottama–6', 'ne': 'तिलोत्तमा–६'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 19,
      name: {'en': 'Mukti Prasad Bhandari', 'ne': 'मुक्तिप्रसाद भण्डारी'},
      position: {'en': 'Member', 'ne': 'सदस्य'},
      phone: '982356402',
      address: {'en': 'Gaurad–6', 'ne': 'गौराड–६'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 20,
      name: {'en': 'Krishna Bhandari', 'ne': 'कृष्ण भण्डारी'},
      position: {'en': 'Member', 'ne': 'सदस्य'},
      phone: '982564485',
      address: {'en': 'Kamal–5', 'ne': 'कमल–५'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 21,
      name: {'en': 'Raghunarayan Bhandari', 'ne': 'रघुनारायण भण्डारी'},
      position: {'en': 'Member', 'ne': 'सदस्य'},
      phone: '982473880',
      address: {'en': 'Arjundhara–11', 'ne': 'अर्जुनधारा–११'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 22,
      name: {'en': 'Tufanath Bhandari', 'ne': 'तुफानाथ भण्डारी'},
      position: {'en': 'Member', 'ne': 'सदस्य'},
      phone: '982482132',
      address: {'en': 'Shivaraj–7 Kapilvastu', 'ne': 'शिवराज–७ कपिलवस्तु'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 23,
      name: {'en': 'Bhimraj Bhandari', 'ne': 'भीमराज भण्डारी'},
      position: {'en': 'Member', 'ne': 'सदस्य'},
      phone: '982466478',
      address: {'en': 'Kapilvastu', 'ne': 'कपिलवस्तु'},
    ),
  ];

  /// Seeds the Bidesh Samiti data if the document doesn't exist.
  Future<void> seedBideshSamitiIfEmpty() async {
    final contentCollection =
        FirebaseFirestore.instance.collection('content');
    final doc = await contentCollection.doc('bidesh_samiti').get();
    if (doc.exists) return;

    final content = KendriyaSamitiContent(
      members: _bideshSamitiData,
      updatedAt: DateTime.now(),
    );
    await contentCollection
        .doc('bidesh_samiti')
        .set(content.toFirestore());
  }

  static final List<KendriyaSamitiMember> _bideshSamitiData = [
    const KendriyaSamitiMember(
      serialNumber: 1,
      name: {'en': 'Dingaram Bhandari', 'ne': 'श्री दिङ्गराम भण्डारी'},
      position: {'en': 'Coordinator', 'ne': 'संयोजक'},
      phone: '9857028605',
      address: {'en': 'Devdaha–6', 'ne': 'देवदह–६'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 2,
      name: {'en': 'Govinda Bhandari', 'ne': 'श्री गोविन्द भण्डारी'},
      position: {'en': 'Co-Coordinator', 'ne': 'सह–संयोजक'},
      phone: '9822966288',
      address: {'en': 'Tilottama–6', 'ne': 'तिलोत्तमा–६'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 3,
      name: {'en': 'Bishnu Dev Bhandari', 'ne': 'श्री विष्णुदेव भण्डारी'},
      position: {'en': 'Secretary', 'ne': 'सचिव'},
      phone: '9822926502',
      address: {'en': 'Tilottama–6', 'ne': 'तिलोत्तमा–६'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 4,
      name: {'en': 'Krishna Prasad Bhandari (Budhe)', 'ne': 'श्री कृष्णप्रसाद भण्डारी (बुढे)'},
      position: {'en': 'Joint Secretary / Treasurer', 'ne': 'सह–सचिव / कोषाध्यक्ष'},
      phone: '9805862048',
      address: {'en': 'Devdaha–6', 'ne': 'देवदह–६'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 5,
      name: {'en': 'Nirmala Bhandari', 'ne': 'श्री निर्मला भण्डारी'},
      position: {'en': 'Member', 'ne': 'सदस्य'},
      phone: '9829725582',
      address: {'en': 'Belbas–5', 'ne': 'बेलवास–५'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 6,
      name: {'en': 'Nirmala Bhandari', 'ne': 'श्री निर्मला भण्डारी'},
      position: {'en': 'Member', 'ne': 'सदस्य'},
      phone: '9853380580',
      address: {'en': 'Ullikhani–2', 'ne': 'उल्लिखनी–२'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 7,
      name: {'en': 'Pitambar Bhandari', 'ne': 'श्री पिताम्बर भण्डारी'},
      position: {'en': 'Member', 'ne': 'सदस्य'},
      phone: '9848262679',
      address: {'en': 'Devdaha', 'ne': 'देवदह'},
    ),
    const KendriyaSamitiMember(
      serialNumber: 8,
      name: {'en': 'Kewal Ram Bhandari', 'ne': 'श्री केवल राम भण्डारी'},
      position: {'en': 'Member', 'ne': 'सदस्य'},
      phone: '',
      address: {'en': 'Tilottama–6', 'ne': 'तिलोत्तमा–६'},
    ),
  ];

  /// Seeds the Committee data if the document doesn't exist.
  Future<void> seedCommitteeIfEmpty() async {
    final contentCollection =
        FirebaseFirestore.instance.collection('content');
    final doc = await contentCollection.doc('committee').get();
    if (doc.exists) return;

    final content = CommitteeContent(
      members: _committeeData,
      updatedAt: DateTime.now(),
    );
    await contentCollection
        .doc('committee')
        .set(content.toFirestore());
  }

  static final List<CommitteeMember> _committeeData = [
    const CommitteeMember(
      id: 'c1',
      name: {'en': 'Krishna Prasad Bhandari Ghairali', 'ne': 'कृष्णप्रसाद भण्डारी घैराली'},
      role: {'en': 'President', 'ne': 'अध्यक्ष'},
    ),
    const CommitteeMember(
      id: 'c2',
      name: {'en': 'Dhanshyam Bhandari', 'ne': 'धनश्याम भण्डारी'},
      role: {'en': 'Senior Vice President', 'ne': 'वरिष्ठ उपाध्यक्ष'},
    ),
    const CommitteeMember(
      id: 'c3',
      name: {'en': 'Keshwar Bhandari', 'ne': 'केशवर भण्डारी'},
      role: {'en': 'Vice President', 'ne': 'उपाध्यक्ष'},
    ),
    const CommitteeMember(
      id: 'c4',
      name: {'en': 'Hari Prasad Bhandari', 'ne': 'हरिप्रसाद भण्डारी'},
      role: {'en': 'Vice President', 'ne': 'उपाध्यक्ष'},
    ),
    const CommitteeMember(
      id: 'c5',
      name: {'en': 'Ranan Bhandari', 'ne': 'राणण भण्डारी'},
      role: {'en': 'Vice President', 'ne': 'उपाध्यक्ष'},
    ),
    const CommitteeMember(
      id: 'c6',
      name: {'en': 'Dev Raj Bhandari', 'ne': 'देवराज भण्डारी'},
      role: {'en': 'Vice President', 'ne': 'उपाध्यक्ष'},
    ),
    const CommitteeMember(
      id: 'c7',
      name: {'en': 'Indra Lal Bhandari', 'ne': 'इन्द्रलाल भण्डारी'},
      role: {'en': 'Vice President', 'ne': 'उपाध्यक्ष'},
    ),
    const CommitteeMember(
      id: 'c8',
      name: {'en': 'Ganga Ram Bhandari', 'ne': 'गंगाराम भण्डारी'},
      role: {'en': 'Vice President', 'ne': 'उपाध्यक्ष'},
    ),
    const CommitteeMember(
      id: 'c9',
      name: {'en': 'Gobinda Bhandari', 'ne': 'गोविन्द भण्डारी'},
      role: {'en': 'General Secretary', 'ne': 'महासचिव'},
    ),
    const CommitteeMember(
      id: 'c10',
      name: {'en': 'Amin Bhandari', 'ne': 'अमिन भण्डारी'},
      role: {'en': 'Secretary', 'ne': 'सचिव'},
    ),
    const CommitteeMember(
      id: 'c11',
      name: {'en': 'Bhola Nath Bhandari', 'ne': 'भोलानाथ भण्डारी'},
      role: {'en': 'Secretary', 'ne': 'सचिव'},
    ),
    const CommitteeMember(
      id: 'c12',
      name: {'en': 'Bishnu Dev Bhandari', 'ne': 'विष्णुदेव भण्डारी'},
      role: {'en': 'Treasurer', 'ne': 'कोषाध्यक्ष'},
    ),
  ];

  /// Seeds elder sayings if the document doesn't exist or has no sayings.
  Future<void> seedElderSayingsIfEmpty() async {
    final contentCollection =
        FirebaseFirestore.instance.collection('content');
    final doc = await contentCollection.doc('elder_sayings').get();
    
    // Only seed if doc doesn't exist. We don't merge or overwrite to preserve user/admin edits.
    if (!doc.exists) {
      final content = ElderSayingsContent(
        sayings: _elderSayingsData,
        updatedAt: DateTime.now(),
      );
      await contentCollection
          .doc('elder_sayings')
          .set(content.toFirestore());
    }
  }

  static final List<ElderSaying> _elderSayingsData = [
    const ElderSaying(
      id: 'elder_1',
      order: 1,
      name: {
        'en': 'Late Pramananda Bhandari',
        'ne': 'स्व. प्रमानन्द भण्डारी',
      },
      title: {
        'en': 'In memory of Late Pramananda Bhandari — By Pitambar Bhandari (Health Service)',
        'ne': 'स्व.प्रमानन्द भण्डारीको स्मृतिमा — नाम : पिताम्बर भण्डारी (स्वास्थ्य सेवा)',
      },
      saying: {
        'en': 'Born in Khamladu in 1996 BS, Shri Pramananda Bhandari was the eldest son of father Lakshman Bhandari and mother Indradhya Bhandari, among three brothers.\n\n'
            'From the very beginning, he stood as a symbol of responsibility, integrity, and assertiveness, presenting an ideal for family and society throughout his life.\n\n'
            'In 2018 BS, braving difficult circumstances, he migrated towards the Madhesh region and began permanent settlement by clearing jungle in the small Barghare area of Damak. Despite hardships, his courage, foresight, and hard work transformed barren land into the center of a fertile life.\n\n'
            'Together with his wife Durgadevi Bhandari, he not only raised four sons and six daughters but also provided them education, values, and practical knowledge for life. Discipline, affection, and compassion formed the foundation of his family.\n\n'
            'Service to society, courage, and a helpful nature were his hallmarks. He selflessly encouraged the village community, supported those facing injustice, and provided reassurance in difficult times. His free land surveying service particularly earned him respect and reverence in society.\n\n'
            'Following ancestral traditions, he arranged worship, rituals, and incense-lamp offerings as directed by the clan. With unwavering devotion to religion, culture, and tradition, he played a leading role in religious ceremonies and cultural programs.\n\n'
            'His contributions to education and social service are memorable—he played a notable role in establishing schools, educational awareness, and genealogy preservation. He guided others toward self-reliance by connecting agriculture with modern technology.\n\n'
            'After a long and virtuous life, he ascended to heaven in 2076 BS. Though his body has departed, the values, principles, and inspiration he planted will forever live on in the family and society.\n\n'
            'Thus, the life of Shri Pramananda Bhandari stands as an immortal saga inscribed in courage, service, religion, tradition, and values—remembering which feels like reading a handwritten memorial etched by the heart.',
        'ne': 'वि.सं. १९९६ सालमा खाम्लाडु मा जन्मिएका श्री प्रमानन्द भण्डारी, पिता लक्ष्मण भण्डारी र माता इन्द्रध्या भण्डारीका सुपुत्र, तीन दाजुभाइमध्ये जेठा सन्तान हुनुहुन्थ्यो।\n'
            'प्रारम्भदेखि नै जिम्मेवारी, सत्यनिष्ठा र हक्की स्वभावका प्रतीक उहाँले जीवनभर परिवार र समाजका लागि आदर्श प्रस्तुत गर्नुभयो।\n\n'
            'वि.सं. २०१८ सालमा कठिन परिस्थितिलाई चिर्दै मधेसतर्फ झरेर दमक को सानो बारघरे क्षेत्रमा झोडा फडानी गरी स्थायी बसोबास आरम्भ गर्नुभयो। कठिनाइका बाबजुद उहाँको साहस, दूरदृष्टि र मेहनतले उजाड भूमिलाई उर्वर जीवनको केन्द्रमा परिणत गर्\u200dयो।\n\n'
            'उहाँकी धर्मपत्नी दुर्गादेवी भण्डारीसँग मिलेर चार छोरा र छ छोरीको पालन–पोषण गर्नु मात्र नभई उनीहरूलाई शिक्षा, संस्कार र जीवनोपयोगी ज्ञान प्रदान गर्नुभयो। अनुशासन, ममता र करुणा उहाँको परिवारको आधार बने।\n\n'
            'समाजप्रति सेवा, आट–हिम्मत र सहयोग गर्ने स्वभाव उहाँको विशेषता थियो। गाउँ–समाजलाई प्रोत्साहन दिने, अन्यायमा परेकालाई सहारा दिने र कठिन घडीमा ढाडस दिने कार्य उहाँले सधैं निःस्वार्थ रूपमा गर्नुभयो। विशेषगरी जग्गा नाप–जाँचमा निःशुल्क सेवा दिने कार्यले समाजमा उहाँको सम्मान र श्रद्धा बढायो।\n\n'
            'श्री भण्डारीले कुलपरम्पराको सम्मानमा कुलको निर्देशन अनुसार पूजा, आजा र धुप–दियोको व्यवस्था गर्नुहुन्थ्यो। धर्म, संस्कृति र परम्पराप्रति अटल श्रद्धा राख्दै उहाँले धार्मिक अनुष्ठान र सांस्कृतिक कार्यक्रममा अग्रणी भूमिका निभाउनुभयो।\n\n'
            'शिक्षा र समाजसेवामा उहाँको योगदान स्मरणीय छ—विद्यालय स्थापना, शैक्षिक जागरण र वंशावली संरक्षणमा उहाँले उल्लेखनीय भूमिका निभाउनुभयो। कृषि पेशालाई आधुनिक प्रविधिसँग जोडी आत्मनिर्भर बन्न मार्गदर्शन दिनुभयो।\n\n'
            'दीर्घ कर्ममय जीवन पश्चात् वि.सं. २०७६ सालमा उहाँ स्वर्गारोहण गर्नुभयो। उहाँको देह विलीन भए पनि उहाँले रोपेका संस्कार, मूल्य र प्रेरणा परिवार र समाजमा सधैं जीवित रहनेछन्।\n\n'
            'यसरी श्री प्रमानन्द भण्डारीको जीवन साहस, सेवा, धर्म, परम्परा र संस्कारमा अंकित अमित गाथा बनेको छ—जसलाई सम्झँदा मनले कोरिएको हस्तलिखित स्मृतिशिला सम्झन हुन्छ।',
      },
    ),
    const ElderSaying(
      id: 'elder_2',
      order: 2,
      name: {
        'en': 'Krishna (Buddhinath) Bhandari',
        'ne': 'कृष्ण (बुद्धिनाथ) भण्डारी',
      },
      title: {
        'en': 'Damak-9, Campus Mode (Jhapa) | Personal Profile',
        'ne': 'दमक ९ क्याम्पस मोड (झापा) | आत्मवृत्तान्त',
      },
      saying: {
        'ne': 'कृष्ण (बुद्धिनाथ) भण्डारी एक सरल, मेहनती र प्रेरणादायी व्यक्तित्व हुनुहुन्छ। कृषक परिवारमा जन्मिएर उहाँले आफ्नो जीवनको सुरुवात कृषि पेशाबाट गर्नुभयो। सानैदेखि मेहनत, अनुशासन र जिम्मेवारीलाई आत्मसात गर्दै उहाँले आफ्नो जीवनलाई संघर्षपूर्ण तर सफल यात्रामा रूपान्तरण गर्नुभयो।\n\n'
            'उत्कृष्ट भविष्यको खोजीमा उहाँ वैदेशिक रोजगारीतर्फ लाग्नुभयो। विदेशमा रहँदा भोग्नुपरेका कठिनाइ र चुनौतीहरूलाई सामना गर्दै उहाँले आफ्नो परिवारलाई सुदृढ र सफल बनाउन महत्वपूर्ण योगदान दिनुभयो।\n\n'
            'परिवार\n'
            'उहाँकी धर्मपत्नी तिला भण्डारी हुनुहुन्छ।\n'
            'उहाँका एक छोरा र दुई छोरी छन्—\n'
            'छोरा: क्यान्सर विशेषज्ञ चिकित्सक\n'
            'एक छोरी: दन्त चिकित्सक\n'
            'अर्की छोरी: नर्सिङ क्षेत्रमा संलग्न\n\n'
            'यसले उहाँको परिवारमा शिक्षा, सेवा र समर्पणको उच्च मूल्य रहेको देखाउँछ।\n\n'
            'व्यक्तित्व र योगदान\n'
            'मेहनती र आत्मनिर्भर\n'
            'परिवारप्रति समर्पित\n'
            'सामाजिक भावना भएका\n'
            'नेपाली संस्कृति र परम्पराप्रति सम्मान\n\n'
            'परम्परागत पहिरनमा देखिने उहाँको व्यक्तित्वले नेपालीपन र गरिमालाई झल्काउँछ।',
        'en': 'Krishna (Buddhinath) Bhandari is a humble, hardworking, and inspiring individual. Born into a farming family, he began his life through agricultural work. From an early age, he embraced values like hard work, discipline, and responsibility, transforming his life into a journey marked by struggle but ultimately success.\n\n'
            'In pursuit of a better future, he went abroad for employment. Despite facing many hardships and challenges while living overseas, he played a vital role in building a strong and successful family.\n\n'
            'Family\n'
            'His wife is Tila Bhandari.\n'
            'He has one son and two daughters:\n'
            'Son: A cancer specialist doctor\n'
            'One daughter: A dentist\n'
            'Another daughter: Involved in the nursing field\n\n'
            'This reflects the strong emphasis on education, service, and dedication within his family.\n\n'
            'Personality and Contributions\n'
            'Hardworking and self-reliant\n'
            'Devoted to his family\n'
            'Socially responsible\n'
            'Respectful of Nepali culture and traditions\n\n'
            'His presence in traditional attire reflects a deep sense of Nepali identity and dignity.',
      },
    ),
  ];
}
