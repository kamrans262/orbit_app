import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/orbit_colors.dart';
import '../../../core/design_system/orbit_spacing.dart';
import '../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../core/widgets/orbit_feedback_state.dart';
import '../../../core/widgets/orbit_glass_card.dart';
import '../domain/support_content.dart';
import 'support_providers.dart';

class SupportPage extends ConsumerWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(supportContentProvider);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const OrbitAtmosphereBackground(),
        SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  OrbitSpacing.xs,
                  OrbitSpacing.xs,
                  OrbitSpacing.sm,
                  OrbitSpacing.xs,
                ),
                child: Row(
                  children: <Widget>[
                    const BackButton(),
                    Expanded(
                      child: Text(
                        'Help & support',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh support content',
                      onPressed: () => ref.invalidate(supportContentProvider),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: content.when(
                  loading: () => const OrbitLoadingState(),
                  error: (_, _) => OrbitErrorState(
                    title: 'Support content could not be loaded',
                    message: 'Check your connection and try again.',
                    onRetry: () => ref.invalidate(supportContentProvider),
                  ),
                  data: (value) => _SupportBody(content: value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupportBody extends StatelessWidget {
  const _SupportBody({required this.content});

  final SupportContent? content;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width >= 720
        ? 680.0
        : double.infinity;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        OrbitSpacing.lg,
        OrbitSpacing.md,
        OrbitSpacing.lg,
        OrbitSpacing.xxl,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              OrbitGlassCard(
                padding: const EdgeInsets.all(OrbitSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.support_agent_rounded,
                      color: OrbitColors.primary,
                    ),
                    const SizedBox(height: OrbitSpacing.sm),
                    Text(
                      content?.title ?? 'Orbit support',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: OrbitSpacing.sm),
                    Text(
                      content?.body ??
                          'No published support article is available from Orbit right now. You can still review the privacy, security, notification, and subscription controls below.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: OrbitSpacing.lg),
              Text(
                'Quick help',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: OrbitSpacing.sm),
              _SupportLink(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy center',
                subtitle:
                    'Export data, review privacy state, or manage account deletion.',
                onTap: () => context.push('/privacy'),
              ),
              const SizedBox(height: OrbitSpacing.sm),
              _SupportLink(
                icon: Icons.devices_rounded,
                title: 'Security & devices',
                subtitle: 'Review trusted devices and signed-in sessions.',
                onTap: () => context.push('/security/sessions'),
              ),
              const SizedBox(height: OrbitSpacing.sm),
              _SupportLink(
                icon: Icons.notifications_none_rounded,
                title: 'Notification preferences',
                subtitle: 'Control categories and quiet hours.',
                onTap: () => context.push('/notifications/preferences'),
              ),
              const SizedBox(height: OrbitSpacing.sm),
              _SupportLink(
                icon: Icons.workspace_premium_outlined,
                title: 'Subscription',
                subtitle: 'Review your current plan and entitlements.',
                onTap: () => context.push('/subscription'),
              ),
              const SizedBox(height: OrbitSpacing.lg),
              OrbitGlassCard(
                padding: const EdgeInsets.all(OrbitSpacing.lg),
                tint: OrbitColors.surfaceSoft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.verified_user_outlined,
                      color: OrbitColors.teal,
                    ),
                    const SizedBox(width: OrbitSpacing.sm),
                    Expanded(
                      child: Text(
                        'The current consumer API does not expose support-ticket creation. Orbit will not send your request to admin-only support endpoints or pretend a ticket was submitted. Published support content comes through the consumer content API.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportLink extends StatelessWidget {
  const _SupportLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: OrbitColors.primary),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
