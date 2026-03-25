import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bhandari_pariwar/services/storage_service.dart';

/// A photo widget that first tries the stored [photoUrl].
/// If it fails (404 / deleted file) or is null, it automatically resolves
/// the actual file in [storageDirectory] via Supabase Storage list API.
class SmartPhoto extends StatefulWidget {
  final String? photoUrl;
  final String? storageDirectory;
  final double size;

  const SmartPhoto({
    super.key,
    required this.photoUrl,
    this.storageDirectory,
    required this.size,
  });

  @override
  State<SmartPhoto> createState() => _SmartPhotoState();
}

class _SmartPhotoState extends State<SmartPhoto> {
  String? _resolvedUrl;
  bool _primaryFailed = false;
  bool _isResolving = false;
  bool _resolveFailed = false;

  @override
  void initState() {
    super.initState();
    // If no photoUrl exists but a storage directory is available,
    // resolve immediately.
    if ((widget.photoUrl == null || widget.photoUrl!.isEmpty) &&
        widget.storageDirectory != null) {
      _resolveFromStorage();
    }
  }

  @override
  void didUpdateWidget(SmartPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl ||
        oldWidget.storageDirectory != widget.storageDirectory) {
      _primaryFailed = false;
      _resolvedUrl = null;
      _resolveFailed = false;
      if ((widget.photoUrl == null || widget.photoUrl!.isEmpty) &&
          widget.storageDirectory != null) {
        _resolveFromStorage();
      }
    }
  }

  Future<void> _resolveFromStorage() async {
    if (_isResolving || widget.storageDirectory == null) return;
    _isResolving = true;

    final storage = StorageService();
    final url =
        await storage.resolveDirectoryPhotoUrl(widget.storageDirectory!);

    if (mounted) {
      setState(() {
        _resolvedUrl = url;
        _isResolving = false;
        _resolveFailed = url == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Case 1: primary URL exists and hasn't failed yet → try it.
    if (!_primaryFailed &&
        widget.photoUrl != null &&
        widget.photoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.photoUrl!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        placeholder: (_, __) => SizedBox(
          width: widget.size,
          height: widget.size,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) {
          // Primary URL failed (file deleted / renamed).
          // Kick off a resolve and show placeholder meanwhile.
          if (!_primaryFailed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _primaryFailed = true);
                _resolveFromStorage();
              }
            });
          }
          return _placeholderIcon(widget.size);
        },
      );
    }

    // Case 2: resolving in progress.
    if (_isResolving) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Case 3: we have a resolved URL from storage directory listing.
    if (_resolvedUrl != null && _resolvedUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: _resolvedUrl!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        placeholder: (_, __) => SizedBox(
          width: widget.size,
          height: widget.size,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => _placeholderIcon(widget.size),
      );
    }

    // Case 4: no URL at all → placeholder.
    return _placeholderIcon(widget.size);
  }
}

Widget _placeholderIcon(double size) {
  return Container(
    width: size,
    height: size,
    color: const Color(0xFFF5E6C8),
    child: Icon(
      Icons.person,
      size: size * 0.5,
      color: const Color(0xFF6D4C2A),
    ),
  );
}
