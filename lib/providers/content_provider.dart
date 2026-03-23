import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/models/about_content.dart';
import 'package:bhandari_pariwar/models/committee_member.dart';
import 'package:bhandari_pariwar/models/elder_saying.dart';
import 'package:bhandari_pariwar/models/kendriya_samiti.dart';
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

final kendriyaSamitiProvider = StreamProvider<KendriyaSamitiContent?>((ref) {
  final service = ref.watch(contentServiceProvider);
  return service.watchKendriyaSamiti();
});

final bideshSamitiProvider = StreamProvider<KendriyaSamitiContent?>((ref) {
  final service = ref.watch(contentServiceProvider);
  return service.watchBideshSamiti();
});

final elderSayingsProvider = StreamProvider<ElderSayingsContent?>((ref) {
  final service = ref.watch(contentServiceProvider);
  return service.watchElderSayings();
});

final memorialSayingsProvider = StreamProvider<ElderSayingsContent?>((ref) {
  final service = ref.watch(contentServiceProvider);
  return service.watchMemorialSayings();
});
