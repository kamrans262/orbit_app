import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/network/orbit_api_exception.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../../circles/presentation/widgets/circle_screen_scaffold.dart';
import '../messaging_providers.dart';

class MessagingSecurityPage extends ConsumerStatefulWidget {
  const MessagingSecurityPage({super.key});

  @override
  ConsumerState<MessagingSecurityPage> createState() =>
      _MessagingSecurityPageState();
}

class _MessagingSecurityPageState extends ConsumerState<MessagingSecurityPage> {
  bool _updating = false;
  String? _error;

  Future<void> _setReadReceipts(bool enabled) async {
    setState(() {
      _updating = true;
      _error = null;
    });
    try {
      await ref.read(messagingServiceProvider).updateReadReceipts(enabled);
      ref.invalidate(messagingSettingsProvider);
    } on OrbitApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } on Object {
      if (mounted) {
        setState(() => _error = 'Orbit could not update messaging settings.');
      }
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fingerprint = ref.watch(messagingIdentityFingerprintProvider);
    final settings = ref.watch(messagingSettingsProvider);

    return CircleScreenScaffold(
      title: 'Messaging security',
      subtitle: 'Private keys stay on this device',
      body: ListView(
        children: <Widget>[
          CircleContentPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                OrbitGlassCard(
                  padding: const EdgeInsets.all(OrbitSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        Icons.verified_user_rounded,
                        size: 32,
                        color: OrbitColors.success,
                      ),
                      const SizedBox(height: OrbitSpacing.sm),
                      Text(
                        'End-to-end encryption is active',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: OrbitSpacing.xs),
                      Text(
                        'Orbit encrypts message text on your device. Laravel stores and routes opaque ciphertext envelopes only.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: OrbitSpacing.md),
                      Text(
                        'This device fingerprint',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: OrbitSpacing.xs),
                      fingerprint.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const Text(
                          'Fingerprint unavailable',
                          style: TextStyle(color: OrbitColors.danger),
                        ),
                        data: (value) => SelectableText(
                          value,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontFamily: 'monospace',
                                color: OrbitColors.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: OrbitSpacing.lg),
                Text('Privacy', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: OrbitSpacing.sm),
                settings.when(
                  loading: () => const OrbitLoadingState(),
                  error: (_, _) => OrbitErrorState(
                    title: 'Messaging settings unavailable',
                    message:
                        'Pull the page again when your connection is available.',
                    onRetry: () => ref.invalidate(messagingSettingsProvider),
                  ),
                  data: (value) => OrbitGlassCard(
                    child: SwitchListTile.adaptive(
                      value: value.readReceiptsEnabled,
                      onChanged: _updating ? null : _setReadReceipts,
                      secondary: const Icon(
                        Icons.done_all_rounded,
                        color: OrbitColors.primary,
                      ),
                      title: const Text('Read receipts'),
                      subtitle: const Text(
                        'Let Circle members receive server-authorized read state when you open their messages.',
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: OrbitSpacing.sm),
                  Text(
                    _error!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: OrbitColors.danger),
                  ),
                ],
                const SizedBox(height: OrbitSpacing.lg),
                Text(
                  'On-device protection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: OrbitSpacing.sm),
                const _SecurityFact(
                  icon: Icons.key_rounded,
                  title: 'Private identity keys',
                  message:
                      'Stored in secure device storage, never uploaded to Laravel.',
                ),
                const SizedBox(height: OrbitSpacing.sm),
                const _SecurityFact(
                  icon: Icons.storage_rounded,
                  title: 'Encrypted local history',
                  message:
                      'Message bodies are encrypted again before SQLite persistence.',
                ),
                const SizedBox(height: OrbitSpacing.sm),
                const _SecurityFact(
                  icon: Icons.cloud_outlined,
                  title: 'Opaque server transport',
                  message:
                      'The backend receives recipient ciphertext envelopes and delivery metadata, not plaintext.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityFact extends StatelessWidget {
  const _SecurityFact({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      padding: const EdgeInsets.all(OrbitSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: OrbitColors.primary),
          const SizedBox(width: OrbitSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: OrbitSpacing.xxs),
                Text(message, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
