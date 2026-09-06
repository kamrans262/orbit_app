import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../../../core/widgets/orbit_primary_button.dart';
import '../../domain/orbit_circle.dart';
import '../circle_providers.dart';
import '../widgets/circle_screen_scaffold.dart';

class CreateCircleInvitePage extends ConsumerStatefulWidget {
  const CreateCircleInvitePage({required this.circleId, super.key});

  final String circleId;

  @override
  ConsumerState<CreateCircleInvitePage> createState() =>
      _CreateCircleInvitePageState();
}

class _CreateCircleInvitePageState
    extends ConsumerState<CreateCircleInvitePage> {
  int _expiresInMinutes = 1440;
  int _maxUses = 10;
  OrbitCircleInvite? _invite;

  @override
  Widget build(BuildContext context) {
    final circle = ref.watch(circleDetailProvider(widget.circleId));
    final mutation = ref.watch(circleMutationControllerProvider);

    return CircleScreenScaffold(
      title: 'Invite member',
      subtitle: circle.asData?.value.name,
      body: circle.when(
        loading: () => const OrbitLoadingState(),
        error: (_, _) => OrbitErrorState(
          title: 'Circle could not be loaded',
          message: 'Try again before creating an invite.',
          onRetry: () => ref.invalidate(circleDetailProvider(widget.circleId)),
        ),
        data: (value) {
          if (!value.canManageMembers) {
            return const OrbitEmptyState(
              title: 'Invite unavailable',
              message: 'Only a Circle owner or admin can create invite codes.',
            );
          }
          return SingleChildScrollView(
            child: CircleContentPadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (_invite == null) ...<Widget>[
                    Text(
                      'Create a limited invite code. Orbit validates expiry and usage limits on the server.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: OrbitSpacing.lg),
                    DropdownButtonFormField<int>(
                      initialValue: _expiresInMinutes,
                      decoration: const InputDecoration(
                        labelText: 'Invite expires in',
                        prefixIcon: Icon(Icons.schedule_rounded),
                      ),
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem(value: 60, child: Text('1 hour')),
                        DropdownMenuItem(value: 360, child: Text('6 hours')),
                        DropdownMenuItem(value: 1440, child: Text('24 hours')),
                        DropdownMenuItem(value: 10080, child: Text('7 days')),
                      ],
                      onChanged: mutation.isBusy
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _expiresInMinutes = value);
                              }
                            },
                    ),
                    const SizedBox(height: OrbitSpacing.md),
                    DropdownButtonFormField<int>(
                      initialValue: _maxUses,
                      decoration: const InputDecoration(
                        labelText: 'Maximum uses',
                        prefixIcon: Icon(Icons.people_outline_rounded),
                      ),
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem(value: 1, child: Text('1 use')),
                        DropdownMenuItem(value: 5, child: Text('5 uses')),
                        DropdownMenuItem(value: 10, child: Text('10 uses')),
                        DropdownMenuItem(value: 25, child: Text('25 uses')),
                        DropdownMenuItem(value: 100, child: Text('100 uses')),
                      ],
                      onChanged: mutation.isBusy
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _maxUses = value);
                              }
                            },
                    ),
                    if (mutation.hasErrorFor(const <CircleMutationKind>{
                      CircleMutationKind.createInvite,
                    })) ...<Widget>[
                      const SizedBox(height: OrbitSpacing.md),
                      Text(
                        mutation.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: OrbitSpacing.xl),
                    OrbitPrimaryButton(
                      label: 'Create invite code',
                      icon: Icons.key_rounded,
                      isBusy: mutation.isBusy,
                      onPressed: _create,
                    ),
                  ] else
                    _InviteResult(invite: _invite!),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _create() async {
    final invite = await ref
        .read(circleMutationControllerProvider.notifier)
        .createInvite(
          circleId: widget.circleId,
          input: CreateCircleInviteInput(
            expiresInMinutes: _expiresInMinutes,
            maxUses: _maxUses,
          ),
        );
    if (invite != null && mounted) {
      setState(() => _invite = invite);
    }
  }
}

class _InviteResult extends StatelessWidget {
  const _InviteResult({required this.invite});

  final OrbitCircleInvite invite;

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      padding: const EdgeInsets.all(OrbitSpacing.lg),
      tint: OrbitColors.primary.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.verified_rounded, color: OrbitColors.success),
          const SizedBox(height: OrbitSpacing.sm),
          Text(
            'Invite ready',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: OrbitSpacing.md),
          SelectableText(
            invite.code,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
              color: OrbitColors.primary,
            ),
          ),
          const SizedBox(height: OrbitSpacing.sm),
          Text(
            'Up to ${invite.maxUses} uses • Expires ${_formatDateTime(invite.expiresAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: OrbitSpacing.lg),
          OrbitPrimaryButton(
            label: 'Copy invite code',
            icon: Icons.copy_rounded,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: invite.code));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite code copied.')),
                );
              }
            },
          ),
          const SizedBox(height: OrbitSpacing.sm),
          Text(
            'The code is shown only from this create-invite response. Store or share it now.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hour:$minute';
  }
}
