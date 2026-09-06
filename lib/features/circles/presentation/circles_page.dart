import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/orbit_colors.dart';
import '../../../core/design_system/orbit_spacing.dart';
import '../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../core/widgets/orbit_feedback_state.dart';
import '../../../core/widgets/orbit_glass_card.dart';
import 'circle_providers.dart';
import 'widgets/circle_list_card.dart';

class CirclesPage extends ConsumerWidget {
  const CirclesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circles = ref.watch(circlesProvider);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const OrbitAtmosphereBackground(),
        SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(circlesProvider);
              await ref.read(circlesProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: _Header(
                    onCreate: () => context.push('/circles/create'),
                    onJoin: () => context.push('/circles/join'),
                  ),
                ),
                circles.when(
                  loading: () => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: OrbitLoadingState(),
                  ),
                  error: (_, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: OrbitErrorState(
                      title: 'Circles could not be loaded',
                      message: 'Check your connection and try again.',
                      onRetry: () => ref.invalidate(circlesProvider),
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: OrbitEmptyState(
                          title: 'No Circles yet',
                          message:
                              'Create a private Circle or join one with an invite code.',
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        OrbitSpacing.md,
                        OrbitSpacing.xs,
                        OrbitSpacing.md,
                        112,
                      ),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: OrbitSpacing.sm),
                        itemBuilder: (context, index) {
                          final circle = items[index];
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 820),
                              child: CircleListCard(
                                circle: circle,
                                onTap: () =>
                                    context.push('/circles/${circle.id}'),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onCreate, required this.onJoin});

  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OrbitSpacing.md,
        OrbitSpacing.lg,
        OrbitSpacing.md,
        OrbitSpacing.md,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Your Circles',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: OrbitSpacing.xs),
              Text(
                'Private groups for presence, Pings, moments, and safety.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: OrbitSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.add_rounded,
                      label: 'Create Circle',
                      accent: OrbitColors.primary,
                      onTap: onCreate,
                    ),
                  ),
                  const SizedBox(width: OrbitSpacing.sm),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.key_rounded,
                      label: 'Join with code',
                      accent: OrbitColors.purple,
                      onTap: onJoin,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(OrbitSpacing.md),
      tint: accent.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: accent),
          const SizedBox(height: OrbitSpacing.sm),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
