import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/location/current_location_reader.dart';
import '../../../../core/network/orbit_api_exception.dart';
import '../../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../domain/sos_models.dart';
import '../sos_providers.dart';
import '../widgets/sos_responder_card.dart';
import '../widgets/sos_status_card.dart';

class SosIncidentPage extends ConsumerStatefulWidget {
  const SosIncidentPage({required this.sosId, super.key});

  final String sosId;

  @override
  ConsumerState<SosIncidentPage> createState() => _SosIncidentPageState();
}

class _SosIncidentPageState extends ConsumerState<SosIncidentPage>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  Timer? _locationTimer;
  bool _sharingLocation = false;
  bool _publishingLocation = false;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        ref.invalidate(sosIncidentProvider(widget.sosId));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_setLocationSharing(false));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incident = ref.watch(sosIncidentProvider(widget.sosId));
    final mutation = ref.watch(sosMutationControllerProvider);
    final auth = ref.watch(authControllerProvider).asData?.value;
    final userId = auth?.user?.id;

    return Scaffold(
      backgroundColor: OrbitColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const OrbitAtmosphereBackground(),
          SafeArea(
            child: incident.when(
              loading: () => const OrbitLoadingState(),
              error: (error, _) => OrbitErrorState(
                title: 'SOS incident could not be loaded',
                message: error is OrbitApiException
                    ? error.message
                    : 'Check your connection and try again.',
                onRetry: () =>
                    ref.invalidate(sosIncidentProvider(widget.sosId)),
              ),
              data: (value) => _IncidentContent(
                incident: value,
                currentUserId: userId,
                mutation: mutation,
                sharingLocation: _sharingLocation,
                locationMessage: _locationMessage,
                onRefresh: _refresh,
                onEngage: userId == null
                    ? null
                    : () => _respond(userId, SosResponderStatus.engaged),
                onDecline: userId == null
                    ? null
                    : () => _respond(userId, SosResponderStatus.declined),
                onLocationSharingChanged: value.isActive
                    ? _setLocationSharing
                    : null,
                onResolve: _resolve,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(sosIncidentProvider(widget.sosId));
    await ref.read(sosIncidentProvider(widget.sosId).future);
  }

  Future<void> _respond(int userId, SosResponderStatus status) async {
    final incident = await ref
        .read(sosMutationControllerProvider.notifier)
        .respond(userId: userId, sosId: widget.sosId, status: status);
    if (!mounted || incident == null) {
      return;
    }
    if (status == SosResponderStatus.declined) {
      await _setLocationSharing(false);
    }
  }

  Future<void> _resolve(SosResolutionReason reason) async {
    final incident = await ref
        .read(sosMutationControllerProvider.notifier)
        .resolve(sosId: widget.sosId, reason: reason);
    if (!mounted || incident == null) {
      return;
    }
    await _setLocationSharing(false);
  }

  Future<void> _setLocationSharing(bool enabled) async {
    if (!enabled) {
      _locationTimer?.cancel();
      _locationTimer = null;
      if (mounted) {
        setState(() {
          _sharingLocation = false;
          _locationMessage = 'Live SOS location sharing paused.';
        });
      }
      return;
    }

    if (_sharingLocation) {
      return;
    }
    if (mounted) {
      setState(() {
        _sharingLocation = true;
        _locationMessage =
            'Sharing foreground SOS location about once per second.';
      });
    }
    await _publishCurrentLocation();
    if (!_sharingLocation || !mounted) {
      return;
    }
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_publishCurrentLocation());
    });
  }

  Future<void> _publishCurrentLocation() async {
    if (_publishingLocation || !_sharingLocation) {
      return;
    }
    _publishingLocation = true;
    try {
      final location = await ref.read(sosLocationReaderProvider).read();
      await ref
          .read(sosRepositoryProvider)
          .updateLocation(
            sosId: widget.sosId,
            latitude: location.latitude,
            longitude: location.longitude,
            accuracyMeters: location.accuracyMeters,
          );
      if (mounted) {
        setState(() => _locationMessage = 'Live SOS location updated.');
      }
    } on LocationAccessException catch (error) {
      _stopLocationAfterFailure(error.message);
    } on OrbitApiException catch (error) {
      if (error.code == 'sos_location_forbidden' ||
          error.code == 'sos_not_active') {
        _stopLocationAfterFailure(error.message);
      } else if (mounted) {
        setState(
          () => _locationMessage =
              'Location update will retry while this screen stays open.',
        );
      }
    } on Object {
      if (mounted) {
        setState(
          () => _locationMessage =
              'Location update will retry while this screen stays open.',
        );
      }
    } finally {
      _publishingLocation = false;
    }
  }

  void _stopLocationAfterFailure(String message) {
    _locationTimer?.cancel();
    _locationTimer = null;
    if (mounted) {
      setState(() {
        _sharingLocation = false;
        _locationMessage = message;
      });
    }
  }
}

class _IncidentContent extends StatelessWidget {
  const _IncidentContent({
    required this.incident,
    required this.currentUserId,
    required this.mutation,
    required this.sharingLocation,
    required this.locationMessage,
    required this.onRefresh,
    required this.onEngage,
    required this.onDecline,
    required this.onLocationSharingChanged,
    required this.onResolve,
  });

  final SosIncident incident;
  final int? currentUserId;
  final SosMutationState mutation;
  final bool sharingLocation;
  final String? locationMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback? onEngage;
  final VoidCallback? onDecline;
  final Future<void> Function(bool enabled)? onLocationSharingChanged;
  final Future<void> Function(SosResolutionReason reason) onResolve;

  @override
  Widget build(BuildContext context) {
    final isOriginator =
        currentUserId != null && incident.originatorUserId == currentUserId;
    final myResponder = currentUserId == null
        ? null
        : incident.responderFor(currentUserId!);
    final mayShareLocation =
        incident.isActive &&
        (isOriginator || myResponder?.status == SosResponderStatus.engaged);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          OrbitSpacing.lg,
          OrbitSpacing.md,
          OrbitSpacing.lg,
          OrbitSpacing.xxl,
        ),
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
                  'SOS incident',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: OrbitSpacing.lg),
          SosStatusCard(incident: incident),
          const SizedBox(height: OrbitSpacing.md),
          if (incident.isActive &&
              !isOriginator &&
              myResponder != null) ...<Widget>[
            _ResponderActions(
              responder: myResponder,
              isBusy: mutation.isBusy,
              onEngage: onEngage,
              onDecline: onDecline,
            ),
            const SizedBox(height: OrbitSpacing.md),
          ],
          if (mayShareLocation) ...<Widget>[
            OrbitGlassCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile.adaptive(
                value: sharingLocation,
                onChanged: onLocationSharingChanged == null
                    ? null
                    : (value) {
                        unawaited(onLocationSharingChanged!(value));
                      },
                title: const Text('Share live SOS location'),
                subtitle: const Text(
                  'Foreground-only updates are sent about once per second while this screen stays open.',
                ),
                secondary: const Icon(
                  Icons.my_location_rounded,
                  color: OrbitColors.primary,
                ),
              ),
            ),
            if (locationMessage != null) ...<Widget>[
              const SizedBox(height: OrbitSpacing.xs),
              Text(
                locationMessage!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: OrbitSpacing.md),
          ],
          if (mutation.errorMessage != null) ...<Widget>[
            OrbitGlassCard(
              tint: OrbitColors.danger.withValues(alpha: 0.08),
              padding: const EdgeInsets.all(OrbitSpacing.md),
              child: Text(
                mutation.errorMessage!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: OrbitColors.danger),
              ),
            ),
            const SizedBox(height: OrbitSpacing.md),
          ],
          _LocationSummary(incident: incident),
          const SizedBox(height: OrbitSpacing.lg),
          Text('Responders', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: OrbitSpacing.sm),
          if (incident.responders.isEmpty)
            const OrbitGlassCard(
              padding: EdgeInsets.all(OrbitSpacing.md),
              child: Text(
                'No other Circle responders are currently available.',
              ),
            )
          else
            ...incident.responders.map(
              (responder) => Padding(
                padding: const EdgeInsets.only(bottom: OrbitSpacing.sm),
                child: SosResponderCard(responder: responder),
              ),
            ),
          if (isOriginator && incident.isActive) ...<Widget>[
            const SizedBox(height: OrbitSpacing.lg),
            FilledButton.tonalIcon(
              onPressed: mutation.isBusy
                  ? null
                  : () => _showResolveSheet(context),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Resolve SOS'),
            ),
          ],
          const SizedBox(height: OrbitSpacing.lg),
          Text(
            'SOS location is separate from normal Presence privacy. The backend restricts sensitive responder location and encrypted recording references to the SOS participants authorized by the existing contract.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _showResolveSheet(BuildContext context) async {
    final reason = await showModalBottomSheet<SosResolutionReason>(
      context: context,
      useSafeArea: true,
      backgroundColor: OrbitColors.backgroundElevated,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(OrbitSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Resolve SOS',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: OrbitSpacing.xs),
              const Text('Choose why this emergency incident is ending.'),
              const SizedBox(height: OrbitSpacing.md),
              ...SosResolutionReason.values.map(
                (item) => ListTile(
                  leading: const Icon(Icons.check_rounded),
                  title: Text(item.label),
                  onTap: () => Navigator.of(context).pop(item),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (reason != null) {
      await onResolve(reason);
    }
  }
}

class _ResponderActions extends StatelessWidget {
  const _ResponderActions({
    required this.responder,
    required this.isBusy,
    required this.onEngage,
    required this.onDecline,
  });

  final SosResponder responder;
  final bool isBusy;
  final VoidCallback? onEngage;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    if (responder.status == SosResponderStatus.engaged) {
      return const OrbitGlassCard(
        tint: Color(0x1F2DDE8A),
        padding: EdgeInsets.all(OrbitSpacing.md),
        child: Text('You are engaged as a responder for this SOS.'),
      );
    }
    if (responder.status == SosResponderStatus.declined) {
      return const OrbitGlassCard(
        padding: EdgeInsets.all(OrbitSpacing.md),
        child: Text('You declined this SOS response.'),
      );
    }

    return OrbitGlassCard(
      tint: OrbitColors.danger.withValues(alpha: 0.08),
      padding: const EdgeInsets.all(OrbitSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Can you respond?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: OrbitSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: isBusy ? null : onEngage,
                  icon: const Icon(Icons.volunteer_activism_rounded),
                  label: const Text('I can help'),
                ),
              ),
              const SizedBox(width: OrbitSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : onDecline,
                  child: const Text('Decline'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationSummary extends StatelessWidget {
  const _LocationSummary({required this.incident});

  final SosIncident incident;

  @override
  Widget build(BuildContext context) {
    final origin = incident.originatorLocation;
    return OrbitGlassCard(
      padding: const EdgeInsets.all(OrbitSpacing.md),
      child: Row(
        children: <Widget>[
          const Icon(Icons.location_on_rounded, color: OrbitColors.danger),
          const SizedBox(width: OrbitSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Originator location',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  origin == null
                      ? 'No SOS location has been shared yet.'
                      : '${origin.latitude.toStringAsFixed(5)}, ${origin.longitude.toStringAsFixed(5)}${origin.accuracyMeters == null ? '' : ' • ±${origin.accuracyMeters!.round()} m'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
