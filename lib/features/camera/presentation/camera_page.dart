import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/orbit_colors.dart';
import '../../../core/design_system/orbit_spacing.dart';
import '../../../core/widgets/orbit_feedback_state.dart';
import '../../circles/domain/orbit_circle.dart';
import '../../circles/presentation/circle_providers.dart';
import '../../media/domain/media_models.dart';
import '../../moments/domain/moment_models.dart';

class CameraPage extends ConsumerStatefulWidget {
  const CameraPage({this.initialCircleId, super.key});

  final String? initialCircleId;

  @override
  ConsumerState<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState<CameraPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const <CameraDescription>[];
  int _cameraIndex = 0;
  String? _selectedCircleId;
  bool _videoMode = false;
  bool _captureBusy = false;
  bool _videoStopInProgress = false;
  bool _initializing = true;
  String? _errorMessage;
  Timer? _videoTimer;
  int _videoSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedCircleId = widget.initialCircleId;
    _initializeCameras();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed && _cameras.isNotEmpty) {
      _initializeController(_cameras[_cameraIndex]);
    }
  }

  Future<void> _initializeCameras() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('NO_CAMERA', 'No camera is available.');
      }
      _cameras = cameras;
      _cameraIndex = cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      if (_cameraIndex < 0) {
        _cameraIndex = 0;
      }
      await _initializeController(cameras[_cameraIndex]);
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initializing = false;
        _errorMessage = _cameraErrorMessage(error);
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _initializing = false;
        _errorMessage = 'Orbit could not start the camera.';
      });
    }
  }

  Future<void> _initializeController(CameraDescription description) async {
    await _controller?.dispose();
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
        _errorMessage = null;
      });
    } on CameraException catch (error) {
      await controller.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _initializing = false;
        _errorMessage = _cameraErrorMessage(error);
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _controller?.value.isRecordingVideo == true) {
      return;
    }
    final nextIndex = (_cameraIndex + 1) % _cameras.length;
    setState(() {
      _cameraIndex = nextIndex;
      _initializing = true;
    });
    await _initializeController(_cameras[nextIndex]);
  }

  Future<void> _capture() async {
    if (_captureBusy) {
      return;
    }
    final controller = _controller;
    final circles =
        ref.read(circlesProvider).asData?.value ?? const <OrbitCircle>[];
    OrbitCircle? circle;
    for (final item in circles) {
      if (item.id == _selectedCircleId) {
        circle = item;
        break;
      }
    }
    if (circle == null && circles.length == 1) {
      circle = circles.single;
    }
    if (controller == null ||
        !controller.value.isInitialized ||
        circle == null) {
      _showMessage('Choose an active Circle before capturing a Moment.');
      return;
    }
    final selectedCircle = circle;

    setState(() => _captureBusy = true);
    try {
      if (_videoMode) {
        if (controller.value.isRecordingVideo) {
          await _finishVideo(selectedCircle);
        } else {
          await controller.startVideoRecording();
          _videoSeconds = 0;
          _videoTimer?.cancel();
          _videoTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
            if (!mounted) {
              return;
            }
            _videoSeconds += 1;
            setState(() {});
            if (_videoSeconds >= 30 &&
                _controller?.value.isRecordingVideo == true &&
                !_videoStopInProgress) {
              await _finishVideo(selectedCircle);
            }
          });
          if (mounted) {
            setState(() {});
          }
        }
      } else {
        final capture = await controller.takePicture();
        if (!mounted) {
          await _deleteCapture(capture.path);
          return;
        }
        await context.push(
          '/camera/review',
          extra: MomentCaptureDraft(
            circleId: selectedCircle.id,
            circleName: selectedCircle.name,
            sourcePath: capture.path,
            kind: OrbitMediaKind.image,
            contentTypeHint: 'image/jpeg',
          ),
        );
      }
    } on CameraException catch (error) {
      if (mounted) {
        _showMessage(_cameraErrorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _captureBusy = false);
      }
    }
  }

  Future<void> _finishVideo(OrbitCircle circle) async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isRecordingVideo ||
        _videoStopInProgress) {
      return;
    }
    _videoStopInProgress = true;
    _videoTimer?.cancel();
    try {
      final capture = await controller.stopVideoRecording();
      _videoSeconds = 0;
      if (!mounted) {
        await _deleteCapture(capture.path);
        return;
      }
      setState(() {});
      await context.push(
        '/camera/review',
        extra: MomentCaptureDraft(
          circleId: circle.id,
          circleName: circle.name,
          sourcePath: capture.path,
          kind: OrbitMediaKind.video,
          contentTypeHint: 'video/mp4',
        ),
      );
    } finally {
      _videoStopInProgress = false;
    }
  }

  Future<void> _deleteCapture(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return;
    }
    try {
      await file.delete();
    } on FileSystemException {
      // Camera captures live in temporary storage. Cleanup is best effort.
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _cameraErrorMessage(CameraException error) {
    return switch (error.code) {
      'CameraAccessDenied' || 'CameraAccessDeniedWithoutPrompt' =>
        'Camera permission is required to capture private Moments.',
      'CameraAccessRestricted' => 'Camera access is restricted on this device.',
      _ => error.description ?? 'Orbit could not use the camera.',
    };
  }

  Future<void> _disposeCamera() async {
    _videoTimer?.cancel();
    _videoTimer = null;
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoTimer?.cancel();
    final controller = _controller;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final circles = ref.watch(circlesProvider);
    if (_initializing) {
      return const Scaffold(body: OrbitLoadingState());
    }
    if (_errorMessage != null) {
      return Scaffold(
        body: OrbitErrorState(
          title: 'Camera unavailable',
          message: _errorMessage!,
          onRetry: () {
            setState(() {
              _initializing = true;
              _errorMessage = null;
            });
            _initializeCameras();
          },
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(body: OrbitLoadingState());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: CameraPreview(controller),
              ),
            ),
            const _CameraShade(),
            Positioned(
              left: OrbitSpacing.md,
              right: OrbitSpacing.md,
              top: OrbitSpacing.sm,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: circles.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const Text(
                        'Circles unavailable',
                        style: TextStyle(color: Colors.white),
                      ),
                      data: (items) => _CircleSelector(
                        circles: items.where((item) => item.isActive).toList(),
                        value: _selectedCircleId,
                        onChanged: (value) =>
                            setState(() => _selectedCircleId = value),
                      ),
                    ),
                  ),
                  const SizedBox(width: OrbitSpacing.sm),
                  IconButton.filledTonal(
                    onPressed: _switchCamera,
                    icon: const Icon(Icons.cameraswitch_rounded),
                  ),
                ],
              ),
            ),
            Positioned(
              left: OrbitSpacing.md,
              right: OrbitSpacing.md,
              bottom: OrbitSpacing.lg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SegmentedButton<bool>(
                    segments: const <ButtonSegment<bool>>[
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Photo'),
                        icon: Icon(Icons.photo_camera_outlined),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Video'),
                        icon: Icon(Icons.videocam_outlined),
                      ),
                    ],
                    selected: <bool>{_videoMode},
                    onSelectionChanged: controller.value.isRecordingVideo
                        ? null
                        : (values) => setState(() => _videoMode = values.first),
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  const SizedBox(height: OrbitSpacing.md),
                  if (controller.value.isRecordingVideo)
                    Padding(
                      padding: const EdgeInsets.only(bottom: OrbitSpacing.sm),
                      child: Text(
                        'Recording ${_videoSeconds}s / 30s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: _captureBusy ? null : _capture,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: controller.value.isRecordingVideo
                            ? OrbitColors.danger
                            : Colors.white,
                        border: Border.all(color: Colors.white70, width: 5),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(color: Colors.black38, blurRadius: 18),
                        ],
                      ),
                      child: Icon(
                        controller.value.isRecordingVideo
                            ? Icons.stop_rounded
                            : _videoMode
                            ? Icons.videocam_rounded
                            : Icons.camera_alt_rounded,
                        color: controller.value.isRecordingVideo
                            ? Colors.white
                            : Colors.black,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: OrbitSpacing.sm),
                  Text(
                    'Media is encrypted on this device before upload.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleSelector extends StatelessWidget {
  const _CircleSelector({
    required this.circles,
    required this.value,
    required this.onChanged,
  });

  final List<OrbitCircle> circles;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = circles.any((item) => item.id == value)
        ? value
        : circles.length == 1
        ? circles.single.id
        : null;
    return DropdownButtonFormField<String>(
      initialValue: effectiveValue,
      dropdownColor: OrbitColors.backgroundElevated,
      decoration: InputDecoration(
        labelText: 'Circle',
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.45),
      ),
      items: circles
          .map(
            (circle) => DropdownMenuItem<String>(
              value: circle.id,
              child: Text(circle.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: circles.isEmpty ? null : onChanged,
    );
  }
}

class _CameraShade extends StatelessWidget {
  const _CameraShade();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.black.withValues(alpha: 0.45),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.58),
            ],
            stops: const <double>[0, 0.45, 1],
          ),
        ),
      ),
    );
  }
}
