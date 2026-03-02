import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/screens/splash/splash_screen.dart';
import 'package:bhandari_pariwar/screens/home/home_screen.dart';
import 'package:bhandari_pariwar/screens/family_tree/family_tree_screen.dart';
import 'package:bhandari_pariwar/screens/notices/notice_detail_screen.dart';
import 'package:bhandari_pariwar/screens/admin/admin_login_screen.dart';
import 'package:bhandari_pariwar/screens/admin/add_member_screen.dart';
import 'package:bhandari_pariwar/screens/admin/add_notice_screen.dart';
import 'package:bhandari_pariwar/screens/admin/edit_content_screen.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final hasSelectedLanguage = ref.watch(hasSelectedLanguageProvider);

  return GoRouter(
    initialLocation: hasSelectedLanguage ? '/home' : '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          return HomeScreen(initialTab: _parseTab(tab));
        },
      ),
      GoRoute(
        path: '/tree',
        builder: (context, state) {
          final memberId = state.uri.queryParameters['memberId'];
          return FamilyTreeScreen(focusMemberId: memberId);
        },
      ),
      GoRoute(
        path: '/notices/:noticeId',
        builder: (context, state) => NoticeDetailScreen(
          noticeId: state.pathParameters['noticeId']!,
        ),
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/add-member',
        builder: (context, state) {
          final parentId = state.uri.queryParameters['parentId'];
          final asSpouse = state.uri.queryParameters['asSpouse'] == 'true';
          return AddMemberScreen(parentId: parentId, asSpouse: asSpouse);
        },
      ),
      GoRoute(
        path: '/admin/edit-member/:memberId',
        builder: (context, state) => AddMemberScreen(
          editMemberId: state.pathParameters['memberId'],
        ),
      ),
      GoRoute(
        path: '/admin/add-notice',
        builder: (context, state) => const AddNoticeScreen(),
      ),
      GoRoute(
        path: '/admin/edit-content/:contentId',
        builder: (context, state) => EditContentScreen(
          contentId: state.pathParameters['contentId']!,
        ),
      ),
    ],
  );
});

int _parseTab(String? tab) {
  switch (tab) {
    case 'tree':
      return 1;
    case 'notices':
      return 2;
    case 'about':
      return 3;
    case 'settings':
      return 4;
    default:
      return 0;
  }
}
