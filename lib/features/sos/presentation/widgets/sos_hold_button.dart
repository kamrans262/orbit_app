import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_radius.dart';
import '../../../../core/design_system/orbit_spacing.dart';

class SosHoldButton extends StatefulWidget {
  const SosHoldButton({
    required this.onCompleted,
    this.enabled = true,
    super.key,
  });

  final VoidCallback onCompleted;
  final bool enabled;

  @override
  State<SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<SosHoldButton>
    with SingleTickerProviderStateMixin {
  static const Duration _holdDuration = Duration(seconds: 3);

  late final AnimationController _controller;
  Timer? _holdTimer;
  bool _isHolding = false;
  bool _completedForGesture = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _holdDuration);
  }

  void _start() {
    if (!widget.enabled || _isHolding) {
      return;
    }

    _holdTimer?.cancel();
    _isHolding = true;
    _completedForGesture = false;
    _controller.forward(from: 0);
    _holdTimer = Timer(_holdDuration, _completeHold);
  }

  void _completeHold() {
    _holdTimer = null;
    if (!mounted || !_isHolding || !widget.enabled || _completedForGesture) {
      return;
    }

    _completedForGesture = true;
    _controller.value = 1;
    widget.onCompleted();
  }

  void _cancel() {
    _isHolding = false;
    _holdTimer?.cancel();
    _holdTimer = null;

    if (_completedForGesture) {
      return;
    }
    _controller.reverse();
  }

  @override
  void didUpdateWidget(covariant SosHoldButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled) {
      _isHolding = false;
      _completedForGesture = false;
      _holdTimer?.cancel();
      _holdTimer = null;
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: 'Emergency SOS',
      hint: 'Press and hold for three seconds to activate SOS',
      child: Listener(
        onPointerDown: widget.enabled ? (_) => _start() : null,
        onPointerUp: widget.enabled ? (_) => _cancel() : null,
        onPointerCancel: widget.enabled ? (_) => _cancel() : null,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              constraints: const BoxConstraints(minHeight: 88),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(OrbitRadius.lg),
                color: OrbitColors.danger.withValues(alpha: 0.12),
                border: Border.all(
                  color: OrbitColors.danger.withValues(alpha: 0.5),
                ),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _controller.value,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(OrbitRadius.lg),
                            color: OrbitColors.danger.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OrbitSpacing.lg,
                      vertical: OrbitSpacing.md,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(
                          Icons.sos_rounded,
                          color: OrbitColors.danger,
                          size: 32,
                        ),
                        const SizedBox(width: OrbitSpacing.sm),
                        Flexible(
                          child: Text(
                            widget.enabled
                                ? 'Hold 3 seconds to activate SOS'
                                : 'SOS activation unavailable',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: OrbitColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
