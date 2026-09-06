import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/location/current_location_reader.dart';
import '../../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../circles/domain/orbit_circle.dart';
import '../../../circles/presentation/circle_providers.dart';
import '../../data/sos_local_state_store.dart';
import '../sos_providers.dart';
import '../widgets/sos_hold_button.dart';

class SosActivationPage extends ConsumerStatefulWidget {
  const SosActivationPage({super.key});

  @override
  ConsumerState<SosActivationPage> createState() => _SosActivationPageState();
}

class _SosActivationPageState extends ConsumerState<SosActivationPage> {
  String? _circleId;
  bool _includeCurrentLocation = true;
  String? _locationWarning;

  @override
  Widget build(BuildContext context) {
    final circles = ref.watch(circlesProvider);
    final recovery = ref.watch(sosRecoveryProvider);
    final mutation = ref.watch(sosMutationControllerProvider);

    return Scaffold(
      backgroundColor: OrbitColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const OrbitAtmosphereBackground(),
          SafeArea(
            child: circles.when(
              loading: () => const OrbitLoadingState(),
              error: (_, _) => OrbitErrorState(
                title: 'SOS could not load your Circles',
                message: 'Check your connection and try again.',
                onRetry: () => ref.invalidate(circlesProvider),
              ),
              data: (items) => _buildContent(
                context,
                items.where((item) => item.isActive).toList(growable: false),
                recovery,
                mutation,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<OrbitCircle> circles,
    AsyncValue<SosLocalIncident?> recovery,
    SosMutationState mutation,
  ) {
    if (_circleId == null && circles.length == 1) {
      _circleId = circles.single.id;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        OrbitSpacing.lg,
        OrbitSpacing.md,
        OrbitSpacing.lg,
        OrbitSpacing.xxl,
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton.filledTonal(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: OrbitSpacing.sm),
              Expanded(
                child: Text(
                  'Emergency SOS',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: OrbitSpacing.lg),
          OrbitGlassCard(
            tint: OrbitColors.danger.withValues(alpha: 0.08),
            padding: const EdgeInsets.all(OrbitSpacing.lg),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'SOS alerts your selected Circle',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: OrbitSpacing.xs),
                Text(
                  'Holding the button for 3 seconds creates an emergency incident. If location is enabled below, the initial location is shared with authorized SOS participants even if normal Presence is hidden.',
                ),
              ],
            ),
          ),
          const SizedBox(height: OrbitSpacing.md),
          recovery.when(
            data: (value) {
              if (value == null) {
                return const SizedBox.shrink();
              }
              final local = value;
              return Padding(
                padding: const EdgeInsets.only(bottom: OrbitSpacing.md),
                child: OrbitGlassCard(
                  padding: const EdgeInsets.all(OrbitSpacing.md),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: OrbitColors.warning,
                      ),
                      const SizedBox(width: OrbitSpacing.sm),
                      const Expanded(
                        child: Text('An active SOS is saved on this device.'),
                      ),
                      TextButton(
                        onPressed: () => context.go('/sos/${local.sosId}'),
                        child: const Text('Resume'),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          if (circles.isEmpty)
            const OrbitEmptyState(
              title: 'No active Circle',
              message:
                  'Create or join an active Circle before using Orbit SOS.',
            )
          else ...<Widget>[
            DropdownButtonFormField<String>(
              initialValue: _circleId,
              decoration: const InputDecoration(
                labelText: 'Emergency Circle',
                prefixIcon: Icon(Icons.groups_rounded),
              ),
              items: circles
                  .map(
                    (circle) => DropdownMenuItem<String>(
                      value: circle.id,
                      child: Text(circle.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: mutation.isBusy
                  ? null
                  : (value) => setState(() => _circleId = value),
            ),
            const SizedBox(height: OrbitSpacing.md),
            OrbitGlassCard(
              padding: EdgeInsets.zero,
              child: Material(
                color: Colors.transparent,
                child: SwitchListTile.adaptive(
                  value: _includeCurrentLocation,
                  onChanged: mutation.isBusy
                      ? null
                      : (value) => setState(() {
                          _includeCurrentLocation = value;
                          _locationWarning = null;
                        }),
                  title: const Text('Include current location'),
                  subtitle: const Text(
                    'Orbit requests foreground location only for this emergency action.',
                  ),
                  secondary: const Icon(
                    Icons.my_location_rounded,
                    color: OrbitColors.primary,
                  ),
                ),
              ),
            ),
            if (_locationWarning != null) ...<Widget>[
              const SizedBox(height: OrbitSpacing.sm),
              Text(
                _locationWarning!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: OrbitColors.warning),
              ),
            ],
            if (mutation.errorMessage != null) ...<Widget>[
              const SizedBox(height: OrbitSpacing.md),
              OrbitGlassCard(
                tint: OrbitColors.danger.withValues(alpha: 0.08),
                padding: const EdgeInsets.all(OrbitSpacing.md),
                child: Text(
                  mutation.errorCode == 'sos_activation_rate_limited'
                      ? '${mutation.errorMessage} If you still need immediate help, contact local emergency services or a trusted person directly.'
                      : mutation.errorMessage!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: OrbitColors.danger),
                ),
              ),
            ],
            const SizedBox(height: OrbitSpacing.lg),
            SosHoldButton(
              enabled: !mutation.isBusy && _circleId != null,
              onCompleted: _activate,
            ),
            const SizedBox(height: OrbitSpacing.sm),
            Text(
              'Orbit does not auto-dial emergency services. Do not rely on Orbit as your only emergency channel.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _activate() async {
    final circleId = _circleId;
    final auth = ref.read(authControllerProvider).asData?.value;
    final userId = auth?.user?.id;
    if (circleId == null || userId == null) {
      return;
    }

    ref.read(sosMutationControllerProvider.notifier).clearError();
    CurrentLocation? location;
    if (_includeCurrentLocation) {
      try {
        location = await ref.read(sosLocationReaderProvider).read();
      } on LocationAccessException catch (error) {
        if (mounted) {
          setState(
            () => _locationWarning =
                '${error.message} SOS can still be activated without location.',
          );
        }
      }
    }

    final incident = await ref
        .read(sosMutationControllerProvider.notifier)
        .activate(userId: userId, circleId: circleId, location: location);
    if (!mounted || incident == null) {
      return;
    }
    context.go('/sos/${incident.id}');
  }
}
