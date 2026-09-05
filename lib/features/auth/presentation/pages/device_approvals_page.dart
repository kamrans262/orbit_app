import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_radius.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/network/orbit_api_exception.dart';
import '../../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../device_approvals_controller.dart';

class DeviceApprovalsPage extends ConsumerWidget {
  const DeviceApprovalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvals = ref.watch(deviceApprovalsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device approvals'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh approvals',
            onPressed: approvals.isLoading
                ? null
                : () => ref
                      .read(deviceApprovalsControllerProvider.notifier)
                      .refreshList(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const OrbitAtmosphereBackground(),
          SafeArea(
            child: approvals.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(OrbitSpacing.xl),
                child: OrbitErrorState(
                  title: 'Approvals could not be loaded',
                  message: _messageFor(error),
                  onRetry: () => ref
                      .read(deviceApprovalsControllerProvider.notifier)
                      .refreshList(),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(OrbitSpacing.xl),
                    child: OrbitEmptyState(
                      title: 'No device approvals yet',
                      message:
                          'Additional-device requests will appear here when this account needs a trusted-device decision.',
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    OrbitSpacing.lg,
                    72,
                    OrbitSpacing.lg,
                    OrbitSpacing.xxl,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: OrbitSpacing.sm),
                  itemBuilder: (context, index) {
                    final approval = items[index];
                    return OrbitGlassCard(
                      padding: const EdgeInsets.all(OrbitSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: OrbitColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    OrbitRadius.md,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.smartphone_rounded,
                                  color: OrbitColors.primary,
                                ),
                              ),
                              const SizedBox(width: OrbitSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Device ${_shortId(approval.deviceId)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _requestedLabel(approval.requestedAt),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              _StatusPill(status: approval.status),
                            ],
                          ),
                          if (approval.isPending) ...<Widget>[
                            const SizedBox(height: OrbitSpacing.lg),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => ref
                                    .read(
                                      deviceApprovalsControllerProvider
                                          .notifier,
                                    )
                                    .approve(approval.deviceId),
                                icon: const Icon(Icons.verified_user_outlined),
                                label: const Text('Approve trusted device'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _shortId(String value) {
    if (value.length <= 8) {
      return value;
    }
    return value.substring(0, 8);
  }

  static String _requestedLabel(DateTime? requestedAt) {
    if (requestedAt == null) {
      return 'Approval request';
    }
    final local = requestedAt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return 'Requested ${local.month}/${local.day} at $hour:$minute';
  }

  static String _messageFor(Object error) {
    if (error is OrbitApiException) {
      return error.message;
    }
    return 'Orbit could not load device approvals. Try again.';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'trusted' => OrbitColors.success,
      'pending' => OrbitColors.warning,
      _ => OrbitColors.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(OrbitRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
