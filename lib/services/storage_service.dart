import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    return await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
  }

  Future<String> uploadMemberPhoto(String memberId, File file) async {
    final ref = _storage.ref('members/$memberId/photo.jpg');
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await ref.getDownloadURL();
  }

  Future<String> uploadCommitteePhoto(String memberId, File file) async {
    final ref = _storage.ref('committee/$memberId/photo.jpg');
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await ref.getDownloadURL();
  }

  Future<String> uploadNoticeImage(String noticeId, File file) async {
    final ref = _storage.ref('notices/$noticeId/image.jpg');
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await ref.getDownloadURL();
  }

  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref(path).delete();
    } catch (_) {}
  }
}
