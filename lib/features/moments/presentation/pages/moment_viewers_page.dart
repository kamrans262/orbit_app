import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../moment_providers.dart';

class MomentViewersPage extends ConsumerWidget {
  const MomentViewersPage({required this.momentId, super.key});

  final String momentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewers = ref.watch(momentViewersProvider(momentId));
    return Scaffold(
      appBar: AppBar(title: const Text('Moment viewers')),
      body: viewers.when(
        loading: () => const OrbitLoadingState(),
        error: (_, _) => OrbitErrorState(
          title: 'Viewers could not be loaded',
          message: 'Only the Moment author can see non-anonymous viewers.',
          onRetry: () => ref.invalidate(momentViewersProvider(momentId)),
        ),
        data: (value) => ListView(
          padding: const EdgeInsets.all(OrbitSpacing.md),
          children: <Widget>[
            Text(
              '${value.totalViews} total • ${value.anonymousViews} anonymous',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: OrbitSpacing.md),
            if (value.viewers.isEmpty)
              const OrbitEmptyState(
                title: 'No visible viewers',
                message: 'Ghost Mode views remain anonymous by design.',
              )
            else
              ...value.viewers.map(
                (viewer) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_rounded),
                  ),
                  title: Text(viewer.name),
                  subtitle: Text(_format(viewer.viewedAt)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _format(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
