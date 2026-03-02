import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/models/notice.dart';
import 'package:bhandari_pariwar/services/notice_service.dart';

final allNoticesProvider = StreamProvider<List<Notice>>((ref) {
  final service = ref.watch(noticeServiceProvider);
  return service.watchAllNotices();
});

final noticeByIdProvider =
    Provider.family<Notice?, String>((ref, noticeId) {
  final notices = ref.watch(allNoticesProvider).valueOrNull ?? [];
  try {
    return notices.firstWhere((n) => n.id == noticeId);
  } catch (_) {
    return null;
  }
});
