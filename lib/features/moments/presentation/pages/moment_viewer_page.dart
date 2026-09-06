import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../../../media/domain/media_models.dart';
import '../../../media/presentation/media_providers.dart';
import '../../domain/moment_models.dart';
import '../moment_providers.dart';

class MomentViewerPage extends ConsumerStatefulWidget {
  const MomentViewerPage({required this.momentId, super.key});

  final String momentId;

  @override
  ConsumerState<MomentViewerPage> createState() => _MomentViewerPageState();
}

class _MomentViewerPageState extends ConsumerState<MomentViewerPage> {
  OrbitMoment? _moment;
  PreparedMediaFile? _prepared;
  VideoPlayerController? _videoController;
  Object? _error;
  bool _loading = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _disposePrepared();
    if (!mounted) {
      return;
    }
    PreparedMediaFile? pendingPrepared;
    VideoPlayerController? pendingVideo;
    try {
      final repository = ref.read(momentsRepositoryProvider);
      final moment = await repository.getMoment(widget.momentId);
      final prepared = await ref
          .read(mediaMomentServiceProvider)
          .prepareMomentMedia(moment);
      pendingPrepared = prepared;
      if (prepared.kind == OrbitMediaKind.video) {
        final video = VideoPlayerController.file(File(prepared.path));
        pendingVideo = video;
        await video.initialize();
        await video.setLooping(true);
      }
      try {
        await repository.recordView(moment.id);
      } on Object {
        // Viewing remains usable if a non-critical view receipt cannot be sent.
      }
      if (!mounted) {
        await _disposePendingMedia(pendingVideo, pendingPrepared);
        return;
      }
      setState(() {
        _moment = moment;
        _prepared = prepared;
        _videoController = pendingVideo;
        _loading = false;
      });
    } on Object catch (error) {
      await _disposePendingMedia(pendingVideo, pendingPrepared);
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    final video = _videoController;
    final prepared = _prepared;
    _videoController = null;
    _prepared = null;
    unawaited(_disposePendingMedia(video, prepared));
    super.dispose();
  }

  Future<void> _disposePrepared() async {
    await _videoController?.dispose();
    _videoController = null;
    final path = _prepared?.path;
    _prepared = null;
    if (path != null) {
      await _deleteFile(path);
    }
  }

  Future<void> _disposePendingMedia(
    VideoPlayerController? video,
    PreparedMediaFile? prepared,
  ) async {
    await video?.dispose();
    if (prepared != null) {
      await _deleteFile(prepared.path);
    }
  }

  Future<void> _deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      try {
        await file.delete();
      } on FileSystemException {
        // Temporary plaintext viewing files are best-effort deleted.
      }
    }
  }

  Future<void> _deleteMoment() async {
    final moment = _moment;
    if (moment == null || _deleting) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Moment?'),
        content: const Text(
          'This removes the Moment for everyone in the Circle.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _deleting = true);
    try {
      await ref.read(momentsRepositoryProvider).deleteMoment(moment.id);
      ref.invalidate(circleMomentsProvider(moment.circleId));
      ref.invalidate(recentMomentsProvider);
      if (mounted) {
        context.pop();
      }
    } on Object {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Moment could not be deleted. Try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: OrbitLoadingState());
    }
    if (_error != null || _moment == null || _prepared == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Moment')),
        body: OrbitErrorState(
          title: 'Moment could not be opened',
          message: 'Orbit could not verify or decrypt this private Moment.',
          onRetry: _load,
        ),
      );
    }

    final moment = _moment!;
    final prepared = _prepared!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.55),
        title: Text(moment.author.name),
        actions: <Widget>[
          if (moment.isMine)
            IconButton(
              tooltip: 'Viewers',
              onPressed: () => context.push('/moments/${moment.id}/viewers'),
              icon: const Icon(Icons.visibility_outlined),
            ),
          if (moment.isMine)
            IconButton(
              tooltip: 'Delete Moment',
              onPressed: _deleting ? null : _deleteMoment,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (prepared.kind == OrbitMediaKind.image)
            InteractiveViewer(
              child: Center(
                child: Image.file(
                  File(prepared.path),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 52,
                  ),
                ),
              ),
            )
          else
            _VideoView(controller: _videoController!),
          Positioned(
            left: OrbitSpacing.md,
            right: OrbitSpacing.md,
            bottom: OrbitSpacing.lg,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(OrbitSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.lock_rounded, color: OrbitColors.success),
                    const SizedBox(width: OrbitSpacing.sm),
                    Expanded(
                      child: Text(
                        'End-to-end encrypted • ${moment.viewCount} views',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoView extends StatefulWidget {
  const _VideoView({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<_VideoView> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
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
                    size: 72,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
