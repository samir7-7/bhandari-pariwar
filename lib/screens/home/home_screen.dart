import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/screens/dashboard/dashboard_screen.dart';
import 'package:bhandari_pariwar/screens/family_tree/family_tree_screen.dart';
import 'package:bhandari_pariwar/screens/notices/notices_screen.dart';
import 'package:bhandari_pariwar/screens/about/about_screen.dart';
import 'package:bhandari_pariwar/screens/settings/settings_screen.dart';
import 'package:bhandari_pariwar/services/seed_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const HomeScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    // Auto-seed family data if Firestore is empty
    Future.microtask(() {
      ref.read(seedServiceProvider).autoSeedIfEmpty();
    });
  }

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final screens = [
      DashboardScreen(onNavigateToTab: _navigateToTab),
      const FamilyTreeScreen(),
      NoticesScreen(onBack: () => _navigateToTab(0)),
      AboutScreen(onBack: () => _navigateToTab(0)),
      SettingsScreen(onBack: () => _navigateToTab(0)),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: l10n.dashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_tree),
            label: l10n.familyTree,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.campaign),
            label: l10n.notices,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.info_outline),
            label: l10n.about,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}
