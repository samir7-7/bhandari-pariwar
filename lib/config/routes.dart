import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/providers/auth_provider.dart';
import 'package:bhandari_pariwar/screens/splash/splash_screen.dart';
import 'package:bhandari_pariwar/screens/home/home_screen.dart';
import 'package:bhandari_pariwar/screens/family_tree/family_tree_screen.dart';
import 'package:bhandari_pariwar/screens/member_detail/member_profile_screen.dart';
import 'package:bhandari_pariwar/screens/notices/notice_detail_screen.dart';
import 'package:bhandari_pariwar/screens/admin/admin_login_screen.dart';
import 'package:bhandari_pariwar/screens/admin/add_member_screen.dart';
import 'package:bhandari_pariwar/screens/admin/add_notice_screen.dart';
import 'package:bhandari_pariwar/screens/admin/edit_content_screen.dart';
import 'package:bhandari_pariwar/screens/admin/user_requests_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final hasApprovedAccess = ref.watch(hasApprovedAccessProvider);
  final isAdmin = ref.watch(isAdminProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          if (!hasApprovedAccess) return const SplashScreen();
          final tab = state.uri.queryParameters['tab'];
          return HomeScreen(initialTab: _parseTab(tab));
        },
      ),
      GoRoute(
        path: '/tree',
        builder: (context, state) {
          if (!hasApprovedAccess) return const SplashScreen();
          final memberId = state.uri.queryParameters['memberId'];
          return FamilyTreeScreen(focusMemberId: memberId);
        },
      ),
      GoRoute(
        path: '/member/:memberId',
        builder: (context, state) {
          if (!hasApprovedAccess) return const SplashScreen();
          return MemberProfileScreen(
            memberId: state.pathParameters['memberId']!,
          );
        },
      ),
      GoRoute(
        path: '/notices/:noticeId',
        builder: (context, state) {
          if (!hasApprovedAccess) return const SplashScreen();
          return NoticeDetailScreen(
            noticeId: state.pathParameters['noticeId']!,
          );
        },
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/add-member',
        builder: (context, state) {
          if (!isAdmin) return const SplashScreen();
          final parentId = state.uri.queryParameters['parentId'];
          final asSpouse = state.uri.queryParameters['asSpouse'] == 'true';
          return AddMemberScreen(parentId: parentId, asSpouse: asSpouse);
        },
      ),
      GoRoute(
        path: '/admin/edit-member/:memberId',
        builder: (context, state) {
          if (!isAdmin) return const SplashScreen();
          return AddMemberScreen(
            editMemberId: state.pathParameters['memberId'],
          );
        },
      ),
      GoRoute(
        path: '/admin/add-notice',
        builder: (context, state) {
          if (!isAdmin) return const SplashScreen();
          return const AddNoticeScreen();
        },
      ),
      GoRoute(
        path: '/admin/edit-content/:contentId',
        builder: (context, state) {
          if (!isAdmin) return const SplashScreen();
          return EditContentScreen(
            contentId: state.pathParameters['contentId']!,
          );
        },
      ),
      GoRoute(
        path: '/admin/user-requests',
        builder: (context, state) {
          if (!isAdmin) return const SplashScreen();
          return const UserRequestsScreen();
        },
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
