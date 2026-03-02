import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/providers/family_tree_provider.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_canvas.dart';

class FamilyTreeScreen extends ConsumerWidget {
  final String? focusMemberId;

  const FamilyTreeScreen({super.key, this.focusMemberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final membersAsync = ref.watch(allMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.familyTree),
        actions: [
          membersAsync.whenOrNull(
                data: (members) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: Text(
                      l10n.familyMembers(members.length),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ) ??
              const SizedBox.shrink(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              final members =
                  ref.read(allMembersProvider).valueOrNull ?? [];
              if (value == 'expand') {
                ref
                    .read(expandedNodesProvider.notifier)
                    .expandAll(members);
              } else if (value == 'collapse') {
                ref.read(expandedNodesProvider.notifier).collapseAll();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'expand',
                child: Text(l10n.expandAll),
              ),
              PopupMenuItem(
                value: 'collapse',
                child: Text(l10n.collapseAll),
              ),
            ],
          ),
        ],
      ),
      body: TreeCanvas(focusMemberId: focusMemberId),
    );
  }
}
