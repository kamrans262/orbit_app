import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_primary_button.dart';
import '../auth_controller.dart';
import '../auth_view_state.dart';
import '../widgets/auth_scaffold.dart';

class DeviceApprovalRequiredPage extends ConsumerWidget {
  const DeviceApprovalRequiredPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref
        .watch(authControllerProvider)
        .when(
          data: (value) => value,
          error: (_, _) => const AuthViewState.signedOut(),
          loading: () => const AuthViewState.signedOut(),
        );

    return AuthScaffold(
      title: 'Approve this device',
      subtitle:
          'Orbit recognized this as an additional device. A trusted Orbit device must approve it before a secure session is issued.',
      footer: TextButton(
        onPressed: state.isBusy
            ? null
            : () => ref.read(authControllerProvider.notifier).startOver(),
        child: const Text('Use a different email'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OrbitColors.warning.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.phonelink_lock_rounded,
              size: 34,
              color: OrbitColors.warning,
            ),
          ),
          const SizedBox(height: OrbitSpacing.lg),
          Text(
            state.deviceName ?? 'This device',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: OrbitSpacing.xs),
          Text(
            state.email ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: OrbitSpacing.lg),
          const _ApprovalStep(
            number: '1',
            text:
                'Open Orbit on a device that is already trusted for this account.',
          ),
          const SizedBox(height: OrbitSpacing.sm),
          const _ApprovalStep(
            number: '2',
            text: 'Open Profile → Device approvals and approve this device.',
          ),
          const SizedBox(height: OrbitSpacing.sm),
          const _ApprovalStep(
            number: '3',
            text:
                'Return here and check the approval. Orbit will then issue the 15-minute access and rotating 60-day refresh credentials.',
          ),
          if (state.errorMessage != null) ...<Widget>[
            const SizedBox(height: OrbitSpacing.md),
            AuthErrorMessage(message: state.errorMessage!),
          ],
          const SizedBox(height: OrbitSpacing.lg),
          OrbitPrimaryButton(
            label: 'Check approval',
            icon: Icons.refresh_rounded,
            isBusy: state.isBusy,
            onPressed: () =>
                ref.read(authControllerProvider.notifier).checkDeviceApproval(),
          ),
        ],
      ),
    );
  }
}

class _ApprovalStep extends StatelessWidget {
  const _ApprovalStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: OrbitColors.primary.withValues(alpha: 0.14),
          ),
          child: Text(
            number,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: OrbitColors.primary),
          ),
        ),
        const SizedBox(width: OrbitSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}
