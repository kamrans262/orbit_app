import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_primary_button.dart';
import '../../../../core/widgets/orbit_text_field.dart';
import '../../domain/orbit_circle.dart';
import '../circle_providers.dart';
import '../widgets/circle_screen_scaffold.dart';

class CreateCirclePage extends ConsumerStatefulWidget {
  const CreateCirclePage({super.key});

  @override
  ConsumerState<CreateCirclePage> createState() => _CreateCirclePageState();
}

class _CreateCirclePageState extends ConsumerState<CreateCirclePage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  CircleType _type = CircleType.standard;
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_rebuildForValidation);
  }

  void _rebuildForValidation() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_rebuildForValidation);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(circleMutationControllerProvider);

    return CircleScreenScaffold(
      title: 'Create Circle',
      subtitle: 'Private by default',
      body: SingleChildScrollView(
        child: CircleContentPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              OrbitTextField(
                controller: _nameController,
                label: 'Circle name',
                hint: 'Family, close friends, trip…',
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.groups_2_outlined,
              ),
              const SizedBox(height: OrbitSpacing.md),
              OrbitTextField(
                controller: _descriptionController,
                label: 'Description (optional)',
                hint: 'What is this Circle for?',
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.notes_rounded,
              ),
              const SizedBox(height: OrbitSpacing.lg),
              Text(
                'Circle type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: OrbitSpacing.xs),
              SegmentedButton<CircleType>(
                segments: const <ButtonSegment<CircleType>>[
                  ButtonSegment<CircleType>(
                    value: CircleType.standard,
                    icon: Icon(Icons.all_inclusive_rounded),
                    label: Text('Standard'),
                  ),
                  ButtonSegment<CircleType>(
                    value: CircleType.temporary,
                    icon: Icon(Icons.schedule_rounded),
                    label: Text('Temporary'),
                  ),
                ],
                selected: <CircleType>{_type},
                onSelectionChanged: mutation.isBusy
                    ? null
                    : (selection) {
                        setState(() {
                          _type = selection.single;
                          if (_type == CircleType.standard) {
                            _expiresAt = null;
                          }
                        });
                      },
              ),
              if (_type == CircleType.temporary) ...<Widget>[
                const SizedBox(height: OrbitSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expires'),
                  subtitle: Text(
                    _expiresAt == null
                        ? 'Choose an expiry time'
                        : _formatDateTime(_expiresAt!),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: mutation.isBusy ? null : _chooseExpiry,
                ),
              ],
              if (mutation.hasErrorFor(const <CircleMutationKind>{
                CircleMutationKind.create,
              })) ...<Widget>[
                const SizedBox(height: OrbitSpacing.md),
                Text(
                  mutation.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: OrbitSpacing.xl),
              OrbitPrimaryButton(
                label: 'Create Circle',
                icon: Icons.add_rounded,
                isBusy: mutation.isBusy,
                onPressed: _canSubmit ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canSubmit {
    if (_nameController.text.trim().isEmpty) {
      return false;
    }
    return _type == CircleType.standard || _expiresAt != null;
  }

  Future<void> _chooseExpiry() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _expiresAt ?? now.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _expiresAt ?? now.add(const Duration(hours: 24)),
      ),
    );
    if (time == null || !mounted) {
      return;
    }

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!selected.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expiry must be in the future.')),
      );
      return;
    }
    setState(() => _expiresAt = selected);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final circle = await ref
        .read(circleMutationControllerProvider.notifier)
        .createCircle(
          CreateCircleInput(
            name: _nameController.text,
            description: _descriptionController.text,
            type: _type,
            expiresAt: _expiresAt,
          ),
        );
    if (circle == null || !mounted) {
      return;
    }
    context.go('/circles/${circle.id}');
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hour:$minute';
  }
}
