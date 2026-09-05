import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_primary_button.dart';
import '../auth_controller.dart';
import '../auth_view_state.dart';
import '../widgets/auth_scaffold.dart';

class AuthLoadingPage extends ConsumerWidget {
  const AuthLoadingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final view = auth.when(
      data: (value) => value,
      error: (_, _) => const AuthViewState.restoreFailed(
        'Orbit could not restore your session.',
      ),
      loading: () => null,
    );

    if (view?.stage == AuthStage.restoreFailed) {
      return AuthScaffold(
        title: 'Connection needed',
        subtitle:
            'Orbit could not safely restore your account state. Your stored credentials were not exposed or logged.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: OrbitColors.warning,
            ),
            const SizedBox(height: OrbitSpacing.lg),
            AuthErrorMessage(
              message: view?.errorMessage ?? 'Unable to restore your session.',
            ),
            const SizedBox(height: OrbitSpacing.lg),
            OrbitPrimaryButton(
              label: 'Try again',
              icon: Icons.refresh_rounded,
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).retryRestore(),
            ),
          ],
        ),
      );
    }

    return const AuthScaffold(
      title: 'Opening Orbit',
      subtitle: 'Restoring your secure device session.',
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: OrbitSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
