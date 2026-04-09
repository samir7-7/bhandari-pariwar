import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/providers/auth_provider.dart';
import 'package:bhandari_pariwar/providers/user_account_provider.dart';
import 'package:bhandari_pariwar/services/auth_service.dart';
import 'package:bhandari_pariwar/services/user_account_service.dart';

class UserRequestsScreen extends ConsumerStatefulWidget {
  const UserRequestsScreen({super.key});

  @override
  ConsumerState<UserRequestsScreen> createState() => _UserRequestsScreenState();
}

class _UserRequestsScreenState extends ConsumerState<UserRequestsScreen> {
  final Set<String> _busyIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final requestsState = ref.watch(pendingUserRequestsProvider);

    if (!isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('Only admins can manage signup requests.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Signup Requests'),
      ),
      body: requestsState.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(
              child: Text('No pending signup requests right now.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = requests[index];
              final isBusy = _busyIds.contains(request.uid);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.fullName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text('Email: ${request.email}'),
                      Text('Contact: ${request.contact}'),
                      Text('Address: ${request.address}'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _approveRequest(request.uid),
                              child: isBusy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Approve'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _deleteRequest(request.uid),
                              child: const Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Could not load signup requests: $error'),
        ),
      ),
    );
  }

  Future<void> _approveRequest(String uid) async {
    final authUser = ref.read(authServiceProvider).currentUser;
    if (authUser == null) return;

    setState(() => _busyIds.add(uid));
    try {
      await ref.read(userAccountServiceProvider).approveRequest(
            uid: uid,
            approvedBy: authUser.uid,
            approvedByEmail: authUser.email ?? '',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup request approved.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(uid));
      }
    }
  }

  Future<void> _deleteRequest(String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete request?'),
        content: const Text(
          'This removes the signup request and the linked account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busyIds.add(uid));
    try {
      await ref.read(userAccountServiceProvider).deleteUserRequestAsAdmin(uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup request deleted.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(uid));
      }
    }
  }
}
