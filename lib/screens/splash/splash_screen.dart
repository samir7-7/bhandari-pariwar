import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bhandari_pariwar/providers/auth_provider.dart';
import 'package:bhandari_pariwar/providers/content_provider.dart';
import 'package:bhandari_pariwar/providers/family_tree_provider.dart';
import 'package:bhandari_pariwar/providers/notice_provider.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';
import 'package:bhandari_pariwar/screens/auth/auth_screen.dart';
import 'package:bhandari_pariwar/screens/auth/pending_approval_screen.dart';
import 'package:bhandari_pariwar/screens/onboarding/notification_permission_screen.dart';
import 'package:bhandari_pariwar/services/auth_service.dart';
import 'package:bhandari_pariwar/services/authorized_data_warmup_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasTriggeredMissingProfileSignOut = false;
  String? _warmupKey;
  Future<void>? _warmupFuture;

  @override
  Widget build(BuildContext context) {
    final hasSelectedLanguage = ref.watch(hasSelectedLanguageProvider);
    final hasPromptedNotifications =
        ref.watch(hasPromptedNotificationsProvider);
    final sessionState = ref.watch(authSessionProvider);

    if (!hasSelectedLanguage) {
      return _LanguageSelectionView(onSelect: _selectLanguage);
    }

    if (!hasPromptedNotifications) {
      return const NotificationPermissionScreen();
    }

    return sessionState.when(
      data: (session) {
        if (session.hasApprovedAccess) {
          final warmupFuture = _getWarmupFuture(session);
          return FutureBuilder<void>(
            future: warmupFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.error == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    ref.invalidate(allMembersProvider);
                    ref.invalidate(allNoticesProvider);
                    ref.invalidate(familyOverviewProvider);
                    ref.invalidate(historyContentProvider);
                    ref.invalidate(committeeProvider);
                    ref.invalidate(kendriyaSamitiProvider);
                    ref.invalidate(bideshSamitiProvider);
                    ref.invalidate(elderSayingsProvider);
                    ref.invalidate(memorialSayingsProvider);
                    context.go('/home');
                  }
                });
                return const _LoadingScaffold(
                  message: 'Opening your account...',
                );
              }

              if (snapshot.error != null) {
                return _WarmupErrorScaffold(
                  message: snapshot.error.toString(),
                  onRetry: _retryWarmup,
                );
              }

              return const _LoadingScaffold(
                message: 'Preparing your account data...',
              );
            },
          );
        }

        if (session.isMissingProfile) {
          if (!_hasTriggeredMissingProfileSignOut) {
            _hasTriggeredMissingProfileSignOut = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await ref.read(authServiceProvider).signOut();
            });
          }
          return const _LoadingScaffold(
            message: 'Refreshing your account...',
          );
        }

        if (session.isPendingApproval) {
          return const PendingApprovalScreen();
        }

        return const AuthScreen();
      },
      loading: () => const _LoadingScaffold(
        message: 'Checking your account...',
      ),
      error: (error, _) => _ErrorScaffold(message: '$error'),
    );
  }

  void _selectLanguage(String code) {
    ref.read(currentLanguageProvider.notifier).setLanguage(code);
    ref.read(hasSelectedLanguageProvider.notifier).markSelected();
  }

  void _retryWarmup() {
    setState(() {
      _warmupKey = null;
      _warmupFuture = null;
    });
  }

  Future<void> _getWarmupFuture(AuthSessionState session) {
    final key =
        '${session.firebaseUser?.uid}:${session.appUser?.status}:${session.appUser?.role}';
    if (_warmupFuture == null || _warmupKey != key) {
      _warmupKey = key;
      _warmupFuture = ref.read(authorizedDataWarmupServiceProvider).waitUntilReady();
    }
    return _warmupFuture!;
  }
}

class _LanguageSelectionView extends StatelessWidget {
  const _LanguageSelectionView({
    required this.onSelect,
  });

  final void Function(String code) onSelect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/vasista_guru.png',
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Bhandari Pariwar',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'भण्डारी परिवार',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
              const SizedBox(height: 40),
              Text(
                'Select your preferred language\nआफ्नो मनपर्ने भाषा छान्नुहोस्',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              _LanguageOption(
                label: 'English',
                onTap: () => onSelect('en'),
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                label: 'नेपाली',
                onTap: () => onSelect('ne'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Theme.of(context).colorScheme.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Something went wrong while loading the app.\n$message',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _WarmupErrorScaffold extends StatelessWidget {
  const _WarmupErrorScaffold({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Could not load app data yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
