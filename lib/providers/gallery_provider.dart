import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/services/storage_service.dart';

/// Provides the list of gallery photo URLs from Supabase Storage.
/// No database involved — photos are listed directly from the storage bucket.
final galleryPhotosProvider =
    AsyncNotifierProvider<GalleryNotifier, List<String>>(GalleryNotifier.new);

class GalleryNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final storage = ref.read(storageServiceProvider);
    return storage.listGalleryPhotos();
  }

  /// Add a new photo to the gallery.
  Future<String> addPhoto(File file) async {
    final storage = ref.read(storageServiceProvider);
    final url = await storage.uploadGalleryPhoto(file);
    // Refresh the list.
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => storage.listGalleryPhotos());
    return url;
  }

  /// Delete a photo from the gallery.
  Future<void> deletePhoto(String publicUrl) async {
    final storage = ref.read(storageServiceProvider);
    await storage.deleteGalleryPhoto(publicUrl);
    // Refresh the list.
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => storage.listGalleryPhotos());
  }

  /// Refresh the gallery.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(storageServiceProvider).listGalleryPhotos());
  }
}
