import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../../../../core/widgets/orbit_glass_card.dart';
import '../../../../core/widgets/orbit_primary_button.dart';
import '../../domain/orbit_profile.dart';
import '../profile_providers.dart';

class EditProfilePage extends ConsumerWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const OrbitAtmosphereBackground(),
        SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  OrbitSpacing.xs,
                  OrbitSpacing.xs,
                  OrbitSpacing.lg,
                  0,
                ),
                child: Row(
                  children: <Widget>[
                    const BackButton(),
                    Expanded(
                      child: Text(
                        'Profile details',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: state.when(
                  loading: () => const OrbitLoadingState(),
                  error: (_, _) => OrbitErrorState(
                    title: 'Profile could not be loaded',
                    message: 'Check your connection and try again.',
                    onRetry: () => ref.invalidate(profileControllerProvider),
                  ),
                  data: (value) => _EditProfileForm(
                    key: ValueKey<String>(
                      '${value.profile.id}:${value.profile.updatedAt?.microsecondsSinceEpoch ?? 0}',
                    ),
                    profile: value.profile,
                    isSaving: value.isSaving,
                    errorMessage: value.errorMessage,
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

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({
    required this.profile,
    required this.isSaving,
    required this.errorMessage,
    super.key,
  });

  final OrbitProfile profile;
  final bool isSaving;
  final String? errorMessage;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _timezoneController;
  late final TextEditingController _localeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name ?? '');
    _timezoneController = TextEditingController(
      text: widget.profile.timezone ?? 'UTC',
    );
    _localeController = TextEditingController(
      text: widget.profile.locale ?? 'en',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timezoneController.dispose();
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 700
            ? OrbitSpacing.xxl
            : OrbitSpacing.md;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            OrbitSpacing.md,
            horizontal,
            OrbitSpacing.xxl,
          ),
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    OrbitGlassCard(
                      padding: const EdgeInsets.all(OrbitSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.profile.email,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: OrbitSpacing.xxs),
                          Text(
                            widget.profile.emailVerifiedAt == null
                                ? 'Email verification pending'
                                : 'Verified Orbit identity',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: widget.profile.emailVerifiedAt == null
                                      ? OrbitColors.warning
                                      : OrbitColors.success,
                                ),
                          ),
                          const SizedBox(height: OrbitSpacing.lg),
                          TextField(
                            controller: _nameController,
                            enabled: !widget.isSaving,
                            textInputAction: TextInputAction.next,
                            maxLength: 100,
                            decoration: const InputDecoration(
                              labelText: 'Display name',
                              hintText: 'How your Circle members see you',
                            ),
                          ),
                          const SizedBox(height: OrbitSpacing.sm),
                          TextField(
                            controller: _timezoneController,
                            enabled: !widget.isSaving,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Timezone',
                              hintText: 'Asia/Karachi',
                            ),
                          ),
                          const SizedBox(height: OrbitSpacing.sm),
                          TextField(
                            controller: _localeController,
                            enabled: !widget.isSaving,
                            textInputAction: TextInputAction.done,
                            autocorrect: false,
                            maxLength: 10,
                            decoration: const InputDecoration(
                              labelText: 'Locale',
                              hintText: 'en-PK',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.errorMessage != null) ...<Widget>[
                      const SizedBox(height: OrbitSpacing.md),
                      Text(
                        widget.errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: OrbitColors.danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: OrbitSpacing.lg),
                    OrbitPrimaryButton(
                      label: 'Save profile',
                      icon: Icons.check_rounded,
                      isBusy: widget.isSaving,
                      onPressed: _save,
                    ),
                    const SizedBox(height: OrbitSpacing.sm),
                    Text(
                      'Email changes are intentionally not offered here because the current consumer API does not expose a verified email-change contract.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save() async {
    final saved = await ref
        .read(profileControllerProvider.notifier)
        .save(
          name: _nameController.text,
          timezone: _timezoneController.text,
          locale: _localeController.text,
        );
    if (!mounted || !saved) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
  }
}
