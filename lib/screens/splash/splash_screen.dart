import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                onTap: () => _selectLanguage(context, ref, 'en'),
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                label: 'नेपाली',
                onTap: () => _selectLanguage(context, ref, 'ne'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _selectLanguage(BuildContext context, WidgetRef ref, String code) {
    ref.read(currentLanguageProvider.notifier).setLanguage(code);
    ref.read(hasSelectedLanguageProvider.notifier).markSelected();
    context.go('/home');
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.onTap,
  });

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
