import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../notification_providers.dart';

class AnnouncementDetailPage extends ConsumerWidget {
  const AnnouncementDetailPage({required this.announcementId, super.key});

  final String announcementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcement = ref.watch(announcementByIdProvider(announcementId));

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const OrbitAtmosphereBackground(),
        SafeArea(
          child: Column(
            children: <Widget>[
              const Align(alignment: Alignment.centerLeft, child: BackButton()),
              Expanded(
                child: announcement.when(
                  loading: () => const OrbitLoadingState(),
                  error: (_, _) => OrbitErrorState(
                    title: 'Announcement could not be loaded',
                    message: 'Check your connection and try again.',
                    onRetry: () => ref.invalidate(
                      announcementByIdProvider(announcementId),
                    ),
                  ),
                  data: (item) {
                    if (item == null) {
                      return const OrbitEmptyState(
                        title: 'Announcement unavailable',
                        message:
                            'It may have expired or no longer applies to your account.',
                      );
                    }
                    final security = item.type.toLowerCase().contains(
                      'security',
                    );
                    final accent = security
                        ? OrbitColors.warning
                        : OrbitColors.primary;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        OrbitSpacing.lg,
                        OrbitSpacing.sm,
                        OrbitSpacing.lg,
                        OrbitSpacing.xxl,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  security
                                      ? Icons.security_rounded
                                      : Icons.campaign_outlined,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(height: OrbitSpacing.lg),
                              Text(
                                item.title,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: OrbitSpacing.md),
                              SelectableText(
                                item.body,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(height: 1.55),
                              ),
                              if (item.endsAt != null) ...<Widget>[
                                const SizedBox(height: OrbitSpacing.xl),
                                Text(
                                  'Available until ${_dateLabel(item.endsAt!)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _dateLabel(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}
