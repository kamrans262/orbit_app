import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../../../core/widgets/orbit_primary_button.dart';
import '../../../../core/widgets/orbit_text_field.dart';
import '../../domain/orbit_circle.dart';
import '../circle_providers.dart';
import '../widgets/circle_screen_scaffold.dart';

class CircleSettingsPage extends ConsumerWidget {
  const CircleSettingsPage({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circle = ref.watch(circleDetailProvider(circleId));

    return CircleScreenScaffold(
      title: 'Circle settings',
      subtitle: circle.asData?.value.name,
      body: circle.when(
        loading: () => const OrbitLoadingState(),
        error: (_, _) => OrbitErrorState(
          title: 'Settings could not be loaded',
          message: 'Check your connection and try again.',
          onRetry: () => ref.invalidate(circleDetailProvider(circleId)),
        ),
        data: (value) => _CircleSettingsContent(circle: value),
      ),
    );
  }
}

class _CircleSettingsContent extends ConsumerStatefulWidget {
  const _CircleSettingsContent({required this.circle});

  final OrbitCircle circle;

  @override
  ConsumerState<_CircleSettingsContent> createState() =>
      _CircleSettingsContentState();
}

class _CircleSettingsContentState
    extends ConsumerState<_CircleSettingsContent> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.circle.name);
    _descriptionController = TextEditingController(
      text: widget.circle.description ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _CircleSettingsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.circle.updatedAt != widget.circle.updatedAt) {
      _nameController.text = widget.circle.name;
      _descriptionController.text = widget.circle.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(circleMutationControllerProvider);
    final circle = widget.circle;

    return SingleChildScrollView(
      child: CircleContentPadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (circle.canEdit) ...<Widget>[
              OrbitGlassCard(
                padding: const EdgeInsets.all(OrbitSpacing.md),
                child: Column(
                  children: <Widget>[
                    OrbitTextField(
                      controller: _nameController,
                      label: 'Circle name',
                      prefixIcon: Icons.groups_2_outlined,
                    ),
                    const SizedBox(height: OrbitSpacing.md),
                    OrbitTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      prefixIcon: Icons.notes_rounded,
                    ),
                    const SizedBox(height: OrbitSpacing.lg),
                    OrbitPrimaryButton(
                      label: 'Save Circle',
                      icon: Icons.save_outlined,
                      isBusy: mutation.isBusy,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: OrbitSpacing.lg),
            ],
            OrbitGlassCard(
              padding: const EdgeInsets.all(OrbitSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Membership',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: OrbitSpacing.sm),
                  if (circle.myRole == CircleRole.owner)
                    Text(
                      'Owners cannot leave through the current API contract. Archive the Circle when it should no longer be active.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    Text(
                      'Leaving removes your membership and access to this Circle.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (circle.canLeave) ...<Widget>[
                    const SizedBox(height: OrbitSpacing.md),
                    OrbitPrimaryButton(
                      label: 'Leave Circle',
                      icon: Icons.logout_rounded,
                      isBusy: mutation.isBusy,
                      backgroundColor: OrbitColors.warning,
                      onPressed: _leave,
                    ),
                  ],
                ],
              ),
            ),
            if (circle.canArchive) ...<Widget>[
              const SizedBox(height: OrbitSpacing.lg),
              OrbitGlassCard(
                padding: const EdgeInsets.all(OrbitSpacing.md),
                tint: OrbitColors.danger.withValues(alpha: 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Archive Circle',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: OrbitColors.danger,
                      ),
                    ),
                    const SizedBox(height: OrbitSpacing.xs),
                    Text(
                      'Archiving disables future Circle modifications. This action is owner-only.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: OrbitSpacing.md),
                    OrbitPrimaryButton(
                      label: 'Archive Circle',
                      icon: Icons.archive_outlined,
                      isBusy: mutation.isBusy,
                      backgroundColor: OrbitColors.danger,
                      onPressed: _archive,
                    ),
                  ],
                ),
              ),
            ],
            if (mutation.hasErrorFor(const <CircleMutationKind>{
              CircleMutationKind.updateCircle,
              CircleMutationKind.leave,
              CircleMutationKind.archive,
            })) ...<Widget>[
              const SizedBox(height: OrbitSpacing.md),
              Text(
                mutation.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Circle name is required.')));
      return;
    }

    final updated = await ref
        .read(circleMutationControllerProvider.notifier)
        .updateCircle(
          circleId: widget.circle.id,
          name: name,
          description: _descriptionController.text,
        );
    if (updated != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Circle updated.')));
    }
  }

  Future<void> _leave() async {
    final confirmed = await _confirm(
      title: 'Leave Circle?',
      message:
          'You will lose access to this Circle until you are invited again.',
      action: 'Leave',
    );
    if (!confirmed || !mounted) {
      return;
    }
    final success = await ref
        .read(circleMutationControllerProvider.notifier)
        .leaveCircle(widget.circle.id);
    if (success && mounted) {
      context.go('/circles');
    }
  }

  Future<void> _archive() async {
    final confirmed = await _confirm(
      title: 'Archive Circle?',
      message:
          'This disables Circle modifications for members. Continue only if this Circle should no longer be active.',
      action: 'Archive',
    );
    if (!confirmed || !mounted) {
      return;
    }
    final success = await ref
        .read(circleMutationControllerProvider.notifier)
        .archiveCircle(widget.circle.id);
    if (success && mounted) {
      context.go('/circles');
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
