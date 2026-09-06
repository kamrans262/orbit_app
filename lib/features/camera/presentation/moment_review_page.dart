import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/design_system/orbit_colors.dart';
import '../../../core/design_system/orbit_spacing.dart';
import '../../../core/widgets/orbit_primary_button.dart';
import '../../media/domain/media_models.dart';
import '../../media/presentation/media_providers.dart';
import '../../moments/domain/moment_models.dart';
import '../../moments/presentation/moment_providers.dart';

class MomentReviewPage extends ConsumerStatefulWidget {
  const MomentReviewPage({required this.draft, super.key});

  final MomentCaptureDraft draft;

  @override
  ConsumerState<MomentReviewPage> createState() => _MomentReviewPageState();
}

class _MomentReviewPageState extends ConsumerState<MomentReviewPage> {
  VideoPlayerController? _video;
  bool _publishing = false;
  double _progress = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.draft.kind == OrbitMediaKind.video) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    final controller = VideoPlayerController.file(
      File(widget.draft.sourcePath),
    );
    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _video = controller);
    } on Object {
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    final video = _video;
    _video = null;
    if (!_publishing) {
      // Retry capture cleanup only after the preview releases the file.
      // publishDraft also deletes on success, but an open video handle can make
      // that first best-effort attempt fail on some platforms.
      unawaited(_disposePreviewAndDraft(video));
    } else if (video != null) {
      unawaited(video.dispose());
    }
    super.dispose();
  }

  Future<void> _disposePreviewAndDraft(VideoPlayerController? video) async {
    await video?.dispose();
    await _deleteDraft();
  }

  Future<void> _deleteDraft() async {
    final file = File(widget.draft.sourcePath);
    if (await file.exists()) {
      try {
        await file.delete();
      } on FileSystemException {
        // Temporary camera file cleanup is best effort.
      }
    }
  }

  Future<void> _publish() async {
    if (_publishing) {
      return;
    }
    setState(() {
      _publishing = true;
      _progress = 0;
      _errorMessage = null;
    });
    try {
      final moment = await ref
          .read(mediaMomentServiceProvider)
          .publishDraft(
            draft: widget.draft,
            onProgress: (value) {
              if (mounted) {
                setState(() => _progress = value);
              }
            },
          );
      ref.invalidate(circleMomentsProvider(moment.circleId));
      ref.invalidate(recentMomentsProvider);
      if (!mounted) {
        return;
      }
      setState(() {
        _publishing = false;
        _progress = 1;
      });
      context.go('/circles/${moment.circleId}/moments');
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _publishing = false;
        _errorMessage =
            'Orbit could not publish this encrypted Moment. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_publishing,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(widget.draft.circleName),
          backgroundColor: Colors.black,
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.black,
                  child: widget.draft.kind == OrbitMediaKind.image
                      ? Image.file(
                          File(widget.draft.sourcePath),
                          fit: BoxFit.contain,
                        )
                      : _VideoPreview(controller: _video),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  OrbitSpacing.md,
                  OrbitSpacing.md,
                  OrbitSpacing.md,
                  OrbitSpacing.lg,
                ),
                decoration: const BoxDecoration(
                  color: OrbitColors.backgroundElevated,
                  border: Border(
                    top: BorderSide(color: OrbitColors.borderSubtle),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.lock_rounded,
                          color: OrbitColors.success,
                        ),
                        const SizedBox(width: OrbitSpacing.sm),
                        Expanded(
                          child: Text(
                            'Only encrypted media and per-device key envelopes are sent to Laravel.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    if (_publishing) ...<Widget>[
                      const SizedBox(height: OrbitSpacing.md),
                      LinearProgressIndicator(
                        value: _progress.clamp(0.0, 1.0).toDouble(),
                      ),
                      const SizedBox(height: OrbitSpacing.xs),
                      Text(
                        _progress < 0.25
                            ? 'Encrypting on device…'
                            : _progress < 0.9
                            ? 'Uploading ciphertext…'
                            : 'Publishing Moment…',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (_errorMessage != null) ...<Widget>[
                      const SizedBox(height: OrbitSpacing.sm),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: OrbitColors.danger),
                      ),
                    ],
                    const SizedBox(height: OrbitSpacing.md),
                    OrbitPrimaryButton(
                      label: _publishing ? 'Publishing…' : 'Publish Moment',
                      icon: Icons.auto_awesome_rounded,
                      onPressed: _publishing ? null : _publish,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  const _VideoPreview({required this.controller});

  final VideoPlayerController? controller;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      onTap: () async {
        if (controller.value.isPlaying) {
          await controller.pause();
        } else {
          await controller.play();
        }
        if (mounted) {
          setState(() {});
        }
      },
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio == 0
              ? 9 / 16
              : controller.value.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              VideoPlayer(controller),
              if (!controller.value.isPlaying)
                const Center(
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white70,
                    size: 72,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
