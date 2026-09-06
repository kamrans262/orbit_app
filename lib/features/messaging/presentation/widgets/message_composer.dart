import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_radius.dart';
import '../../../../core/design_system/orbit_spacing.dart';

class MessageComposer extends StatefulWidget {
  const MessageComposer({
    required this.onSend,
    required this.onTypingChanged,
    required this.isSending,
    super.key,
  });

  final Future<void> Function(String value) onSend;
  final Future<void> Function(bool isTyping) onTypingChanged;
  final bool isSending;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _typingTimer;
  bool _typingSent = false;

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_typingSent) {
      unawaited(widget.onTypingChanged(false));
    }
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final value = _controller.text.trim();
    if (value.isEmpty || widget.isSending) {
      return;
    }
    _typingTimer?.cancel();
    if (_typingSent) {
      _typingSent = false;
      await widget.onTypingChanged(false);
    }
    await widget.onSend(value);
    if (!mounted) {
      return;
    }
    _controller.clear();
    setState(() {});
    _focusNode.requestFocus();
  }

  void _onChanged(String value) {
    setState(() {});
    final hasText = value.trim().isNotEmpty;
    if (hasText && !_typingSent) {
      _typingSent = true;
      unawaited(widget.onTypingChanged(true));
    }
    _typingTimer?.cancel();
    if (hasText) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (_typingSent) {
          _typingSent = false;
          unawaited(widget.onTypingChanged(false));
        }
      });
    } else if (_typingSent) {
      _typingSent = false;
      unawaited(widget.onTypingChanged(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _controller.text.trim().isNotEmpty && !widget.isSending;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          OrbitSpacing.md,
          OrbitSpacing.sm,
          OrbitSpacing.md,
          OrbitSpacing.sm,
        ),
        decoration: const BoxDecoration(
          color: OrbitColors.navigation,
          border: Border(top: BorderSide(color: OrbitColors.borderSubtle)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !widget.isSending,
                minLines: 1,
                maxLines: 5,
                maxLength: 8000,
                onChanged: _onChanged,
                onSubmitted: (_) => _send(),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message your Circle',
                  counterText: '',
                  filled: true,
                  fillColor: OrbitColors.surfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: OrbitSpacing.md,
                    vertical: OrbitSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(OrbitRadius.xl),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: OrbitSpacing.xs),
            Semantics(
              button: true,
              label: 'Send encrypted message',
              child: IconButton.filled(
                onPressed: canSend ? _send : null,
                icon: widget.isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_upward_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
