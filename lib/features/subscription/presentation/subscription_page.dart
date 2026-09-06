import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/orbit_colors.dart';
import '../../../core/design_system/orbit_radius.dart';
import '../../../core/design_system/orbit_spacing.dart';
import '../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../core/widgets/orbit_feedback_state.dart';
import '../../../core/widgets/orbit_glass_card.dart';
import '../domain/orbit_subscription.dart';
import 'subscription_providers.dart';

class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(currentSubscriptionProvider);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const OrbitAtmosphereBackground(),
        SafeArea(
          child: Column(
            children: <Widget>[
              _Header(
                onRefresh: () => ref.invalidate(currentSubscriptionProvider),
              ),
              Expanded(
                child: subscription.when(
                  loading: () => const OrbitLoadingState(),
                  error: (_, _) => OrbitErrorState(
                    title: 'Subscription could not be loaded',
                    message: 'Check your connection and try again.',
                    onRetry: () => ref.invalidate(currentSubscriptionProvider),
                  ),
                  data: (value) => _SubscriptionBody(
                    subscription: value,
                    onRefresh: () async {
                      ref.invalidate(currentSubscriptionProvider);
                      await ref.read(currentSubscriptionProvider.future);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              'Subscription',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          IconButton(
            tooltip: 'Refresh subscription',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionBody extends StatelessWidget {
  const _SubscriptionBody({
    required this.subscription,
    required this.onRefresh,
  });

  final OrbitSubscription subscription;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width >= 720
        ? 680.0
        : double.infinity;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                      Row(
                        children: <Widget>[
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: OrbitColors.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(
                                OrbitRadius.md,
                              ),
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: OrbitColors.primary,
                            ),
                          ),
                          const SizedBox(width: OrbitSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  subscription.plan.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: OrbitSpacing.xxs),
                                Text(
                                  _statusLabel(subscription.status),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: OrbitSpacing.lg),
                      _MetricRow(
                        label: 'Price',
                        value: subscription.complimentary
                            ? 'Complimentary'
                            : _priceLabel(subscription),
                      ),
                      _MetricRow(
                        label: 'Billing interval',
                        value: subscription.billingInterval ?? 'Not applicable',
                      ),
                      if (subscription.currentPeriodEnd != null)
                        _MetricRow(
                          label: 'Current period ends',
                          value: _dateLabel(subscription.currentPeriodEnd!),
                        ),
                      if (subscription.cancelAt != null)
                        _MetricRow(
                          label: 'Scheduled cancellation',
                          value: _dateLabel(subscription.cancelAt!),
                        ),
                      if (subscription.endsAt != null)
                        _MetricRow(
                          label: 'Ends',
                          value: _dateLabel(subscription.endsAt!),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: OrbitSpacing.lg),
                Text(
                  'Entitlements',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: OrbitSpacing.sm),
                OrbitGlassCard(
                  padding: const EdgeInsets.all(OrbitSpacing.lg),
                  child: subscription.entitlements.isEmpty
                      ? Text(
                          'No entitlement details are currently published for this plan.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      : Column(
                          children: subscription.entitlements.entries
                              .map(
                                (entry) => _MetricRow(
                                  label: _humanize(entry.key),
                                  value: _entitlementValue(entry.value),
                                ),
                              )
                              .toList(growable: false),
                        ),
                ),
                const SizedBox(height: OrbitSpacing.lg),
                OrbitGlassCard(
                  padding: const EdgeInsets.all(OrbitSpacing.lg),
                  tint: OrbitColors.surfaceSoft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        Icons.info_outline_rounded,
                        color: OrbitColors.textSecondary,
                      ),
                      const SizedBox(width: OrbitSpacing.sm),
                      Expanded(
                        child: Text(
                          'This screen reflects the subscription state supplied by Orbit. The current consumer API is read-only and does not expose checkout, plan changes, cancellation, or payment credential handling.',
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
      ),
    );
  }

  static String _priceLabel(OrbitSubscription subscription) {
    if (subscription.isFree) {
      return 'Free';
    }
    return '${subscription.priceCurrency} ${(subscription.priceAmountMinor / 100).toStringAsFixed(2)}';
  }

  static String _statusLabel(String value) {
    return _humanize(value);
  }

  static String _dateLabel(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  static String _humanize(String value) {
    final words = value.replaceAll('_', ' ').trim();
    if (words.isEmpty) {
      return value;
    }
    return '${words[0].toUpperCase()}${words.substring(1)}';
  }

  static String _entitlementValue(Object? value) {
    if (value is bool) {
      return value ? 'Included' : 'Not included';
    }
    if (value is num || value is String) {
      return value.toString();
    }
    if (value is Map) {
      final enabled = value['enabled'];
      if (enabled is bool) {
        return enabled ? 'Included' : 'Not included';
      }
      final scalar = value['value'];
      if (scalar is bool) {
        return scalar ? 'Included' : 'Not included';
      }
      if (scalar is num || scalar is String) {
        return scalar.toString();
      }
      return 'Configured';
    }
    return 'Configured';
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: OrbitSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: OrbitSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
