import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
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
  final _cropper = ImageCropper();

  // Keep uploads sharp enough for profile display, but small in storage/bandwidth.
  static const int _maxUploadDimension = 1400;
  static const int _uploadQuality = 72;

  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (picked == null) return null;

      try {
        final cropped = await _cropper.cropImage(
          sourcePath: picked.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 95,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Photo',
              toolbarColor: const ui.Color(0xFF7A552B),
              toolbarWidgetColor: const ui.Color(0xFFFFFFFF),
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              hideBottomControls: false,
            ),
            IOSUiSettings(
              title: 'Crop Photo',
              aspectRatioLockEnabled: false,
              resetAspectRatioEnabled: true,
            ),
          ],
        );

        if (cropped == null) {
          // User cancelled crop dialog.
          return null;
        }

        return XFile(cropped.path);
      } catch (_) {
        // Fallback: if cropper is unavailable on a device/build variant,
        // continue with original picked file instead of crashing upload flow.
        return picked;
      }
    } catch (_) {
      return null;
    }
  }

  Future<String> uploadMemberPhoto(
    String memberId,
    File file, {
    String? previousPublicUrl,
  }) async {
    return _uploadImage(
      directory: 'members/$memberId',
      baseName: 'photo',
      file: file,
      previousPublicUrl: previousPublicUrl,
    );
  }

  Future<String> uploadCommitteePhoto(
    String memberId,
    File file, {
    String? previousPublicUrl,
  }) async {
    return _uploadImage(
      directory: 'committee/$memberId',
      baseName: 'photo',
      file: file,
      previousPublicUrl: previousPublicUrl,
    );
  }

  Future<String> uploadNoticeImage(
    String noticeId,
    File file, {
    String? previousPublicUrl,
  }) async {
    return _uploadImage(
      directory: 'notices/$noticeId',
      baseName: 'image',
      file: file,
      previousPublicUrl: previousPublicUrl,
    );
  }

  Future<String> uploadElderSayingPhoto(
    String sayingId,
    File file, {
    String? previousPublicUrl,
  }) async {
    return _uploadImage(
      directory: 'elder_sayings/$sayingId',
      baseName: 'photo',
      file: file,
      previousPublicUrl: previousPublicUrl,
    );
  }

  Future<String> uploadMemorialSayingPhoto(
    String sayingId,
    File file, {
    String? previousPublicUrl,
  }) async {
    return _uploadImage(
      directory: 'memorial_sayings/$sayingId',
      baseName: 'photo',
      file: file,
      previousPublicUrl: previousPublicUrl,
    );
  }

  Future<String> uploadKendriyaPhoto(
    String memberKey,
    File file, {
    String? previousPublicUrl,
  }) async {
    return _uploadImage(
      directory: 'kendriya_samiti/$memberKey',
      baseName: 'photo',
      file: file,
      previousPublicUrl: previousPublicUrl,
    );
  }

  Future<String> uploadBideshPhoto(
    String memberKey,
    File file, {
    String? previousPublicUrl,
  }) async {
    return _uploadImage(
      directory: 'bidesh_samiti/$memberKey',
      baseName: 'photo',
      file: file,
      previousPublicUrl: previousPublicUrl,
    );
  }

  /// Lists the files in [directory] inside the photos bucket and returns the
  /// public URL of the first image found.  Returns `null` when the directory
  /// is empty or does not exist.  Useful as a fallback when the stored
  /// `photoUrl` points to a file that has been renamed / deleted.
  Future<String?> resolveDirectoryPhotoUrl(String directory) async {
    try {
      await _ensureAuthenticated();
      final files = await _storage
          .from(SupabaseOptions.photosBucket)
          .list(path: directory);

      if (files.isEmpty) return null;

      // Pick the first real file (skip any `.emptyFolderPlaceholder`).
      final file = files.firstWhere(
        (f) => f.name != '.emptyFolderPlaceholder',
        orElse: () => files.first,
      );

      if (file.name == '.emptyFolderPlaceholder') return null;

      final path = '$directory/${file.name}';
      final rawUrl =
          _storage.from(SupabaseOptions.photosBucket).getPublicUrl(path);
      final ts = DateTime.now().millisecondsSinceEpoch;
      return '$rawUrl?v=$ts';
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      await _ensureAuthenticated();
      await _storage.from(SupabaseOptions.photosBucket).remove([path]);
    } catch (_) {}
  }

  Future<void> deleteByPublicUrl(String? publicUrl) async {
    if (publicUrl == null || publicUrl.trim().isEmpty) return;

    final path = _extractStoragePathFromPublicUrl(publicUrl);
    if (path == null || path.isEmpty) return;

    await deleteFile(path);
  }

  Future<String> _uploadImage({
    required String directory,
    required String baseName,
    required File file,
    String? previousPublicUrl,
  }) async {
    await _ensureAuthenticated();

    try {
      final optimized = await _prepareOptimizedImage(file);
      final extension = _fileExtension(optimized.path);
      final ts = DateTime.now().millisecondsSinceEpoch;
      // Use steady path so Supabase overwrites existing image instead of creating duplicates.
      final path = '$directory/$baseName.$extension';

      await _storage.from(SupabaseOptions.photosBucket).upload(
        path,
        optimized,
        fileOptions: FileOptions(
          contentType: _contentTypeFor(extension),
          upsert: true,
        ),
      );

      final rawUrl =
          _storage.from(SupabaseOptions.photosBucket).getPublicUrl(path);
          
      // Bust Flutter's image cache by appending timestamp query to the URL
      final publicUrl = '$rawUrl?v=$ts';

      if (previousPublicUrl != null) {
        final oldPath = _extractStoragePathFromPublicUrl(previousPublicUrl);
        if (oldPath != null && oldPath != path) {
          await deleteByPublicUrl(previousPublicUrl);
        }
      }

      if (optimized.path != file.path) {
        try {
          await optimized.delete();
        } catch (_) {}
      }

      return publicUrl;
    } on StorageException catch (e) {
      final code = e.statusCode ?? '';
      if (code == '403' || e.message.toLowerCase().contains('row-level security')) {
        throw Exception(
          'Supabase Storage policy blocked this upload (403/RLS). '
          'Please add INSERT policy for bucket "${SupabaseOptions.photosBucket}" '
          'for anon/authenticated users.',
        );
      }
      throw Exception('Photo upload failed: ${e.message}');
    }
  }

  Future<File> _prepareOptimizedImage(File file) async {
    try {
      final parent = file.parent.path;
      final outPath =
          '$parent/upload_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        minWidth: _maxUploadDimension,
        minHeight: _maxUploadDimension,
        quality: _uploadQuality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );

      if (compressed == null) return file;
      return File(compressed.path);
    } catch (_) {
      return file;
    }
  }

  String? _extractStoragePathFromPublicUrl(String publicUrl) {
    final uri = Uri.tryParse(publicUrl);
    if (uri == null) return null;

    final segments = uri.pathSegments;
    if (segments.isEmpty) return null;

    final publicIndex = segments.indexOf('public');
    if (publicIndex != -1 && publicIndex + 1 < segments.length) {
      final bucket = segments[publicIndex + 1];
      if (bucket != SupabaseOptions.photosBucket) return null;

      final rest = segments.sublist(publicIndex + 2);
      if (rest.isEmpty) return null;
      return Uri.decodeComponent(rest.join('/'));
    }

    final signIndex = segments.indexOf('sign');
    if (signIndex != -1 && signIndex + 1 < segments.length) {
      final bucket = segments[signIndex + 1];
      if (bucket != SupabaseOptions.photosBucket) return null;

      final rest = segments.sublist(signIndex + 2);
      if (rest.isEmpty) return null;
      return Uri.decodeComponent(rest.join('/'));
    }

    return null;
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

    try {
      await _auth.signInAnonymously();
    } on AuthApiException catch (e) {
      // Many projects intentionally keep anonymous provider disabled and rely
      // on storage policies for the `anon` role (from anon key) instead.
      if (e.code == 'anonymous_provider_disabled' || e.statusCode == 422) {
        return;
      }
      rethrow;
    } catch (_) {
      // Let upload attempt continue; storage policies will decide access.
      return;
    }
  }

  // ── Gallery ──────────────────────────────────────────────────────────

  static const int galleryMaxPhotos = 7;
  static const String _galleryDirectory = 'gallery';

  /// Upload a gallery photo and enforce the max-photo limit.
  Future<String> uploadGalleryPhoto(File file) async {
    await _ensureAuthenticated();

    final optimized = await _prepareOptimizedImage(file);
    final extension = _fileExtension(optimized.path);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '$_galleryDirectory/$ts.$extension';

    await _storage.from(SupabaseOptions.photosBucket).upload(
      path,
      optimized,
      fileOptions: FileOptions(
        contentType: _contentTypeFor(extension),
        upsert: true,
      ),
    );

    final rawUrl =
        _storage.from(SupabaseOptions.photosBucket).getPublicUrl(path);
    final publicUrl = '$rawUrl?v=$ts';

    if (optimized.path != file.path) {
      try {
        await optimized.delete();
      } catch (_) {}
    }

    // Enforce limit — delete oldest photos beyond the max.
    await enforceGalleryLimit();

    return publicUrl;
  }

  /// List all gallery photo URLs sorted newest-first.
  Future<List<String>> listGalleryPhotos() async {
    try {
      await _ensureAuthenticated();
      final files = await _storage
          .from(SupabaseOptions.photosBucket)
          .list(path: _galleryDirectory, searchOptions: const SearchOptions(sortBy: SortBy(column: 'name', order: 'desc')));

      final urls = <String>[];
      for (final file in files) {
        if (file.name == '.emptyFolderPlaceholder') continue;
        final path = '$_galleryDirectory/${file.name}';
        final rawUrl =
            _storage.from(SupabaseOptions.photosBucket).getPublicUrl(path);
        final ts = DateTime.now().millisecondsSinceEpoch;
        urls.add('$rawUrl?v=$ts');
      }
      return urls;
    } catch (_) {
      return [];
    }
  }

  /// Delete a gallery photo by its public URL.
  Future<void> deleteGalleryPhoto(String publicUrl) async {
    await deleteByPublicUrl(publicUrl);
  }

  /// Enforce gallery limit: if more than [galleryMaxPhotos], delete the oldest.
  Future<void> enforceGalleryLimit() async {
    try {
      await _ensureAuthenticated();
      final files = await _storage
          .from(SupabaseOptions.photosBucket)
          .list(path: _galleryDirectory, searchOptions: const SearchOptions(sortBy: SortBy(column: 'name', order: 'asc')));

      // Filter out placeholders.
      final realFiles = files
          .where((f) => f.name != '.emptyFolderPlaceholder')
          .toList();

      if (realFiles.length > galleryMaxPhotos) {
        final toDelete = realFiles.sublist(0, realFiles.length - galleryMaxPhotos);
        for (final file in toDelete) {
          final path = '$_galleryDirectory/${file.name}';
          try {
            await _storage.from(SupabaseOptions.photosBucket).remove([path]);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
