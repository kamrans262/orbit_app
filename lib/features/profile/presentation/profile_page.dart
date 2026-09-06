import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/orbit_colors.dart';
import '../../../core/design_system/orbit_radius.dart';
import '../../../core/design_system/orbit_spacing.dart';
import '../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../core/widgets/orbit_glass_card.dart';
import '../../../core/widgets/orbit_primary_button.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_view_state.dart';
import 'profile_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref
        .watch(authControllerProvider)
        .when(
          data: (value) => value,
          error: (_, _) => const AuthViewState.signedOut(),
          loading: () => const AuthViewState.signedOut(),
        );
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.asData?.value.profile;
    final displayName =
        profile?.displayName ?? auth.user?.displayName ?? 'Orbit member';
    final email = profile?.email ?? auth.user?.email ?? '';
    final maxWidth = MediaQuery.sizeOf(context).width >= 800
        ? 760.0
        : double.infinity;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const OrbitAtmosphereBackground(),
        SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profileControllerProvider);
              await ref.read(profileControllerProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                OrbitSpacing.lg,
                OrbitSpacing.xl,
                OrbitSpacing.lg,
                OrbitSpacing.xxl,
              ),
              children: <Widget>[
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Profile',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: OrbitSpacing.xl),
                        OrbitGlassCard(
                          padding: const EdgeInsets.all(OrbitSpacing.lg),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 58,
                                height: 58,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: <Color>[
                                      OrbitColors.primaryStrong,
                                      OrbitColors.purple,
                                    ],
                                  ),
                                ),
                                child: Text(
                                  _initials(displayName),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              const SizedBox(width: OrbitSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: OrbitSpacing.xxs),
                                    Text(
                                      email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: OrbitSpacing.sm,
                                  vertical: OrbitSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: OrbitColors.success.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    OrbitRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  'Secure',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: OrbitColors.success),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (profileState.hasError) ...<Widget>[
                          const SizedBox(height: OrbitSpacing.sm),
                          Text(
                            'Profile details could not be refreshed. Your authenticated identity is still available.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: OrbitColors.warning),
                          ),
                        ],
                        const SizedBox(height: OrbitSpacing.lg),
                        _Section(
                          title: 'Account',
                          children: <Widget>[
                            _SettingsTile(
                              icon: Icons.person_outline_rounded,
                              iconColor: OrbitColors.primary,
                              title: 'Profile details',
                              subtitle: 'Name, timezone and locale.',
                              onTap: () => context.push('/profile/edit'),
                            ),
                          ],
                        ),
                        const SizedBox(height: OrbitSpacing.lg),
                        _Section(
                          title: 'Privacy',
                          children: <Widget>[
                            _SettingsTile(
                              icon: Icons.privacy_tip_outlined,
                              iconColor: OrbitColors.purple,
                              title: 'Privacy center',
                              subtitle:
                                  'Privacy snapshot, data export and account deletion.',
                              onTap: () => context.push('/privacy'),
                            ),
                            _SettingsTile(
                              icon: Icons.shield_moon_rounded,
                              iconColor: OrbitColors.purple,
                              title: 'Presence & Circle privacy',
                              subtitle:
                                  'Ghost Mode, visibility and Ping permission.',
                              onTap: () => context.push('/presence'),
                            ),
                            _SettingsTile(
                              icon: Icons.notifications_active_outlined,
                              iconColor: OrbitColors.warning,
                              title: 'Notification preferences',
                              subtitle:
                                  'In-app, push, categories and quiet hours.',
                              onTap: () =>
                                  context.push('/notifications/preferences'),
                            ),
                          ],
                        ),
                        const SizedBox(height: OrbitSpacing.lg),
                        _Section(
                          title: 'Security',
                          children: <Widget>[
                            _SettingsTile(
                              icon: Icons.phonelink_lock_rounded,
                              iconColor: OrbitColors.primary,
                              title: 'Device approvals',
                              subtitle:
                                  'Review and approve additional trusted devices.',
                              onTap: () =>
                                  context.push('/security/device-approvals'),
                            ),
                            _SettingsTile(
                              icon: Icons.devices_rounded,
                              iconColor: OrbitColors.teal,
                              title: 'Security & sessions',
                              subtitle:
                                  'Rename devices and revoke signed-in sessions.',
                              onTap: () => context.push('/security/sessions'),
                            ),
                            _SettingsTile(
                              icon: Icons.history_rounded,
                              iconColor: OrbitColors.warning,
                              title: 'Security activity',
                              subtitle:
                                  'Recent identity and account security actions.',
                              onTap: () => context.push('/security/activity'),
                            ),
                            _SettingsTile(
                              icon: Icons.lock_person_rounded,
                              iconColor: OrbitColors.success,
                              title: 'Messaging security',
                              subtitle:
                                  'E2EE device identity, fingerprint and read receipts.',
                              onTap: () => context.push('/security/messaging'),
                            ),
                          ],
                        ),
                        const SizedBox(height: OrbitSpacing.lg),
                        _Section(
                          title: 'Orbit',
                          children: <Widget>[
                            _SettingsTile(
                              icon: Icons.workspace_premium_outlined,
                              iconColor: OrbitColors.primary,
                              title: 'Subscription',
                              subtitle: 'Current plan, price and entitlements.',
                              onTap: () => context.push('/subscription'),
                            ),
                            _SettingsTile(
                              icon: Icons.support_agent_rounded,
                              iconColor: OrbitColors.teal,
                              title: 'Help & support',
                              subtitle:
                                  'Published help content and trusted account shortcuts.',
                              onTap: () => context.push('/support'),
                            ),
                          ],
                        ),
                        if (auth.errorMessage != null) ...<Widget>[
                          const SizedBox(height: OrbitSpacing.lg),
                          Text(
                            auth.errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: OrbitColors.danger),
                          ),
                        ],
                        const SizedBox(height: OrbitSpacing.xl),
                        OrbitPrimaryButton(
                          label: 'Sign out securely',
                          icon: Icons.logout_rounded,
                          isBusy: auth.isBusy,
                          backgroundColor: OrbitColors.danger,
                          onPressed: () => ref
                              .read(authControllerProvider.notifier)
                              .signOut(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'O';
    }
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: OrbitSpacing.sm),
        ...children.expand(
          (child) => <Widget>[
            child,
            if (child != children.last) const SizedBox(height: OrbitSpacing.sm),
          ],
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
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
          leading: Icon(icon, color: iconColor),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
