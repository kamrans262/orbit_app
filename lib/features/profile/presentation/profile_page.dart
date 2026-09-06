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
    final user = auth.user;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const OrbitAtmosphereBackground(),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              OrbitSpacing.lg,
              OrbitSpacing.xl,
              OrbitSpacing.lg,
              OrbitSpacing.xxl,
            ),
            children: <Widget>[
              Text('Profile', style: Theme.of(context).textTheme.headlineLarge),
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
                        _initials(user?.displayName ?? 'Orbit'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: OrbitSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            user?.displayName ?? 'Orbit member',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: OrbitColors.success.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(OrbitRadius.pill),
                      ),
                      child: Text(
                        'Secure',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: OrbitColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: OrbitSpacing.lg),
              Text('Privacy', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: OrbitSpacing.sm),
              OrbitGlassCard(
                child: ListTile(
                  onTap: () => context.push('/presence'),
                  leading: const Icon(
                    Icons.shield_moon_rounded,
                    color: OrbitColors.purple,
                  ),
                  title: const Text('Presence & privacy'),
                  subtitle: const Text(
                    'Global Ghost Mode, Circle visibility and Ping permission.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
              const SizedBox(height: OrbitSpacing.lg),
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: OrbitSpacing.sm),
              OrbitGlassCard(
                child: ListTile(
                  onTap: () => context.push('/notifications/preferences'),
                  leading: const Icon(
                    Icons.notifications_active_outlined,
                    color: OrbitColors.warning,
                  ),
                  title: const Text('Notification preferences'),
                  subtitle: const Text(
                    'In-app, push, categories and quiet hours.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
              const SizedBox(height: OrbitSpacing.lg),
              Text('Security', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: OrbitSpacing.sm),
              OrbitGlassCard(
                child: ListTile(
                  onTap: () => context.push('/security/device-approvals'),
                  leading: const Icon(
                    Icons.phonelink_lock_rounded,
                    color: OrbitColors.primary,
                  ),
                  title: const Text('Device approvals'),
                  subtitle: const Text(
                    'Review and approve additional trusted devices.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
              const SizedBox(height: OrbitSpacing.sm),
              OrbitGlassCard(
                child: ListTile(
                  onTap: () => context.push('/security/messaging'),
                  leading: const Icon(
                    Icons.lock_person_rounded,
                    color: OrbitColors.success,
                  ),
                  title: const Text('Messaging security'),
                  subtitle: const Text(
                    'E2EE device identity, fingerprint and read receipts.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
              const SizedBox(height: OrbitSpacing.lg),
              Text(
                'More profile, privacy, session, export, deletion, support and subscription controls arrive in their dedicated milestone.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (auth.errorMessage != null) ...<Widget>[
                const SizedBox(height: OrbitSpacing.lg),
                Text(
                  auth.errorMessage!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: OrbitColors.danger),
                ),
              ],
              const SizedBox(height: OrbitSpacing.xl),
              OrbitPrimaryButton(
                label: 'Sign out securely',
                icon: Icons.logout_rounded,
                isBusy: auth.isBusy,
                backgroundColor: OrbitColors.danger,
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
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
