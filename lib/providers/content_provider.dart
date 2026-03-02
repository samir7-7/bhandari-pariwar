import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/models/about_content.dart';
import 'package:bhandari_pariwar/models/committee_member.dart';
import 'package:bhandari_pariwar/services/content_service.dart';

final familyOverviewProvider = StreamProvider<AboutContent?>((ref) {
  final service = ref.watch(contentServiceProvider);
  return service.watchContent('family_overview');
});

final historyContentProvider = StreamProvider<AboutContent?>((ref) {
  final service = ref.watch(contentServiceProvider);
  return service.watchContent('history');
});

final committeeProvider = StreamProvider<CommitteeContent?>((ref) {
  final service = ref.watch(contentServiceProvider);
  return service.watchCommittee();
});
