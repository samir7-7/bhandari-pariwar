import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/providers/content_provider.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';

class CommitteeScreen extends ConsumerWidget {
  const CommitteeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final committeeAsync = ref.watch(committeeProvider);
    final langCode = ref.watch(currentLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.committee),
      ),
      body: committeeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
        data: (committee) {
          if (committee == null || committee.members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No committee members yet',
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: committee.members.length,
            itemBuilder: (context, index) {
              final member = committee.members[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (member.photoUrl != null)
                        CircleAvatar(
                          radius: 32,
                          backgroundImage:
                              CachedNetworkImageProvider(member.photoUrl!),
                        )
                      else
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.localizedName(langCode),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              member.localizedRole(langCode),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (member.term != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Term: ${member.term}',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (member.bio != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                member.localizedBio(langCode),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(height: 1.4),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
