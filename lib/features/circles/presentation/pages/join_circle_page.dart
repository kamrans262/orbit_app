import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_primary_button.dart';
import '../../../../core/widgets/orbit_text_field.dart';
import '../circle_providers.dart';
import '../widgets/circle_screen_scaffold.dart';

class JoinCirclePage extends ConsumerStatefulWidget {
  const JoinCirclePage({super.key});

  @override
  ConsumerState<JoinCirclePage> createState() => _JoinCirclePageState();
}

class _JoinCirclePageState extends ConsumerState<JoinCirclePage> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(circleMutationControllerProvider);

    return CircleScreenScaffold(
      title: 'Join a Circle',
      subtitle: 'Invite codes are validated by Orbit',
      body: SingleChildScrollView(
        child: CircleContentPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Enter the invite code shared by a Circle owner or admin.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: OrbitSpacing.lg),
              OrbitTextField(
                controller: _codeController,
                label: 'Invite code',
                hint: 'Example: A1B2C3D4E5',
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.key_rounded,
                onSubmitted: (_) => _submit(),
              ),
              if (mutation.hasErrorFor(const <CircleMutationKind>{
                CircleMutationKind.join,
              })) ...<Widget>[
                const SizedBox(height: OrbitSpacing.md),
                Text(
                  mutation.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: OrbitSpacing.xl),
              OrbitPrimaryButton(
                label: 'Join Circle',
                icon: Icons.login_rounded,
                isBusy: mutation.isBusy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid invite code.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final circle = await ref
        .read(circleMutationControllerProvider.notifier)
        .joinCircle(code);
    if (circle == null || !mounted) {
      return;
    }
    context.go('/circles/${circle.id}');
  }
}
