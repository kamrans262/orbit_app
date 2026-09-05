import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_primary_button.dart';
import '../auth_controller.dart';
import '../auth_view_state.dart';
import '../widgets/auth_scaffold.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  late final TextEditingController _otpController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref
        .watch(authControllerProvider)
        .when(
          data: (value) => value,
          error: (_, _) => const AuthViewState.signedOut(),
          loading: () => const AuthViewState.signedOut(),
        );
    final email = state.email ?? 'your email';
    final remaining = _remaining(state.otpExpiresAt);

    return AuthScaffold(
      title: 'Check your email',
      subtitle: 'Enter the 6-digit Orbit code sent to $email.',
      footer: TextButton(
        onPressed: state.isBusy
            ? null
            : () => ref.read(authControllerProvider.notifier).startOver(),
        child: const Text('Use a different email'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Verification code',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: OrbitSpacing.sm),
          TextField(
            controller: _otpController,
            enabled: !state.isBusy,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.oneTimeCode],
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 28,
              letterSpacing: 10,
            ),
            decoration: const InputDecoration(
              hintText: '000000',
              counterText: '',
            ),
            maxLength: 6,
            onSubmitted: (_) => _verify(state),
          ),
          const SizedBox(height: OrbitSpacing.sm),
          Row(
            children: <Widget>[
              Icon(
                remaining == Duration.zero
                    ? Icons.timer_off_outlined
                    : Icons.timer_outlined,
                size: 18,
                color: remaining == Duration.zero
                    ? OrbitColors.warning
                    : OrbitColors.textMuted,
              ),
              const SizedBox(width: OrbitSpacing.xs),
              Expanded(
                child: Text(
                  remaining == Duration.zero
                      ? 'This code may have expired. Request a new one.'
                      : 'Code expires in ${_formatDuration(remaining)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: state.isBusy
                    ? null
                    : () =>
                          ref.read(authControllerProvider.notifier).resendOtp(),
                child: const Text('Resend'),
              ),
            ],
          ),
          if (state.errorMessage != null) ...<Widget>[
            const SizedBox(height: OrbitSpacing.sm),
            AuthErrorMessage(message: state.errorMessage!),
          ],
          const SizedBox(height: OrbitSpacing.lg),
          OrbitPrimaryButton(
            label: 'Verify and continue',
            icon: Icons.verified_user_outlined,
            isBusy: state.isBusy,
            onPressed: () => _verify(state),
          ),
          const SizedBox(height: OrbitSpacing.md),
          Text(
            'After verification, Orbit registers this device and upgrades the temporary sign-in token into the hardened device-bound Identity session.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _verify(AuthViewState state) {
    if (state.isBusy) {
      return;
    }
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).verifyOtp(_otpController.text);
  }

  Duration _remaining(DateTime? expiresAt) {
    if (expiresAt == null) {
      return Duration.zero;
    }
    final value = expiresAt.toUtc().difference(DateTime.now().toUtc());
    return value.isNegative ? Duration.zero : value;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
