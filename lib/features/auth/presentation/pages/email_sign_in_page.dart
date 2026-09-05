import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_primary_button.dart';
import '../../../../core/widgets/orbit_text_field.dart';
import '../auth_controller.dart';
import '../auth_view_state.dart';
import '../widgets/auth_scaffold.dart';

class EmailSignInPage extends ConsumerStatefulWidget {
  const EmailSignInPage({super.key});

  @override
  ConsumerState<EmailSignInPage> createState() => _EmailSignInPageState();
}

class _EmailSignInPageState extends ConsumerState<EmailSignInPage> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
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

    return AuthScaffold(
      title: 'Stay close, privately.',
      subtitle:
          'Sign in with your email. Orbit uses a short-lived code instead of a password.',
      footer: Text(
        'Your session credentials are stored in secure device storage. Sensitive authorization stays server-side.',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: OrbitColors.textMuted),
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Email address',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: OrbitSpacing.sm),
            OrbitTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.email],
              prefixIcon: Icons.alternate_email_rounded,
              enabled: !state.isBusy,
              onSubmitted: (_) => _submit(state),
            ),
            if (state.errorMessage != null) ...<Widget>[
              const SizedBox(height: OrbitSpacing.sm),
              AuthErrorMessage(message: state.errorMessage!),
            ],
            const SizedBox(height: OrbitSpacing.lg),
            OrbitPrimaryButton(
              label: 'Continue securely',
              icon: Icons.arrow_forward_rounded,
              isBusy: state.isBusy,
              onPressed: () => _submit(state),
            ),
            const SizedBox(height: OrbitSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.lock_outline_rounded,
                  color: OrbitColors.success,
                  size: 18,
                ),
                const SizedBox(width: OrbitSpacing.xs),
                Expanded(
                  child: Text(
                    'No password to remember. Codes expire automatically and repeated attempts are rate-limited by Orbit.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit(AuthViewState state) {
    if (state.isBusy) {
      return;
    }
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).requestOtp(_emailController.text);
  }
}
