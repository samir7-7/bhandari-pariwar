import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bhandari_pariwar/config/supabase_options.dart';

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

class StorageService {
  SupabaseStorageClient get _storage =>
      Supabase.instance.client.storage;
  GoTrueClient get _auth => Supabase.instance.client.auth;

  static const _supportedExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  };

  final _picker = ImagePicker();

  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    return await _picker.pickImage(
      source: source,
      maxWidth: 640,
      maxHeight: 640,
      imageQuality: 70,
    );
  }

  Future<String> uploadMemberPhoto(String memberId, File file) async {
    return _uploadImage(
      directory: 'members/$memberId',
      baseName: 'photo',
      file: file,
    );
  }

  Future<String> uploadCommitteePhoto(String memberId, File file) async {
    return _uploadImage(
      directory: 'committee/$memberId',
      baseName: 'photo',
      file: file,
    );
  }

  Future<String> uploadNoticeImage(String noticeId, File file) async {
    return _uploadImage(
      directory: 'notices/$noticeId',
      baseName: 'image',
      file: file,
    );
  }

  Future<String> uploadElderSayingPhoto(String sayingId, File file) async {
    return _uploadImage(
      directory: 'elder_sayings/$sayingId',
      baseName: 'photo',
      file: file,
    );
  }

  Future<String> uploadKendriyaPhoto(String memberKey, File file) async {
    return _uploadImage(
      directory: 'kendriya_samiti/$memberKey',
      baseName: 'photo',
      file: file,
    );
  }

  Future<String> uploadBideshPhoto(String memberKey, File file) async {
    return _uploadImage(
      directory: 'bidesh_samiti/$memberKey',
      baseName: 'photo',
      file: file,
    );
  }

  Future<void> deleteFile(String path) async {
    try {
      await _ensureAuthenticated();
      await _storage.from(SupabaseOptions.photosBucket).remove([path]);
    } catch (_) {}
  }

  Future<String> _uploadImage({
    required String directory,
    required String baseName,
    required File file,
  }) async {
    await _ensureAuthenticated();

    final extension = _fileExtension(file.path);
    final path = '$directory/$baseName.$extension';

    await _removeImageVariants(directory: directory, baseName: baseName);

    await _storage.from(SupabaseOptions.photosBucket).upload(
          path,
          file,
          fileOptions: FileOptions(
            contentType: _contentTypeFor(extension),
            upsert: true,
          ),
        );

    return _storage.from(SupabaseOptions.photosBucket).getPublicUrl(path);
  }

  Future<void> _removeImageVariants({
    required String directory,
    required String baseName,
  }) async {
    final paths = _supportedExtensions
        .map((extension) => '$directory/$baseName.$extension')
        .toList();

    try {
      await _storage.from(SupabaseOptions.photosBucket).remove(paths);
    } catch (_) {}
  }

  String _fileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1 || lastDot == path.length - 1) {
      return 'jpg';
    }

    final extension = path.substring(lastDot + 1).toLowerCase();
    return _supportedExtensions.contains(extension) ? extension : 'jpg';
  }

  String _contentTypeFor(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _ensureAuthenticated() async {
    if (_auth.currentSession != null) {
      return;
    }

    await _auth.signInAnonymously();
  }
}
