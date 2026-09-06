import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/orbit_colors.dart';
import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/network/orbit_api_exception.dart';
import '../../../../core/widgets/orbit_atmosphere_background.dart';
import '../../../../core/widgets/orbit_feedback_state.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../realtime/presentation/realtime_providers.dart';
import '../../application/messaging_service.dart';
import '../../domain/e2ee_identity.dart';
import '../../domain/messaging_models.dart';
import '../messaging_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_composer.dart';

class CircleMessagesPage extends ConsumerStatefulWidget {
  const CircleMessagesPage({required this.circleId, super.key});

  final String circleId;

  @override
  ConsumerState<CircleMessagesPage> createState() => _CircleMessagesPageState();
}

class _CircleMessagesPageState extends ConsumerState<CircleMessagesPage> {
  bool _sending = false;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    ref
        .read(realtimeActiveConversationProvider.notifier)
        .setActive(widget.circleId);
  }

  @override
  void dispose() {
    ref
        .read(realtimeActiveConversationProvider.notifier)
        .clear(widget.circleId);
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(circleConversationProvider(widget.circleId));
    await ref.read(circleConversationProvider(widget.circleId).future);
  }

  Future<void> _send(String value) async {
    final auth = await ref.read(authControllerProvider.future);
    final user = auth.user;
    if (user == null) {
      return;
    }
    setState(() {
      _sending = true;
      _actionError = null;
    });
    try {
      await ref
          .read(messagingServiceProvider)
          .sendText(
            circleId: widget.circleId,
            senderUserId: user.id,
            plaintext: value,
          );
      ref.invalidate(circleConversationProvider(widget.circleId));
      await ref.read(circleConversationProvider(widget.circleId).future);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _actionError = _messageFor(error));
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _retry(LocalMessage message) async {
    setState(() => _actionError = null);
    try {
      await ref.read(messagingServiceProvider).retryMessage(message: message);
      ref.invalidate(circleConversationProvider(widget.circleId));
      await ref.read(circleConversationProvider(widget.circleId).future);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _actionError = _messageFor(error));
      }
    }
  }

  Future<void> _typing(bool isTyping) async {
    try {
      await ref
          .read(messagingServiceProvider)
          .sendTyping(widget.circleId, isTyping);
    } on Object {
      // Typing is ephemeral and must never block composing or sending.
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(circleConversationProvider(widget.circleId));
    final typingUsers = ref.watch(
      realtimeTypingProvider.select(
        (state) => state[widget.circleId] ?? const <int>{},
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Messages'),
            Text(
              'End-to-end encrypted',
              style: TextStyle(fontSize: 11, color: OrbitColors.textMuted),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Messaging security',
            onPressed: () => context.push('/security/messaging'),
            icon: const Icon(Icons.lock_outline_rounded),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const OrbitAtmosphereBackground(),
          SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                if (_actionError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(OrbitSpacing.sm),
                    color: OrbitColors.danger.withValues(alpha: 0.12),
                    child: Text(
                      _actionError!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: OrbitColors.danger,
                      ),
                    ),
                  ),
                Expanded(
                  child: conversation.when(
                    loading: () => const OrbitLoadingState(),
                    error: (error, _) => OrbitErrorState(
                      title: 'Messages could not be opened',
                      message: _messageFor(error),
                      onRetry: () => ref.invalidate(
                        circleConversationProvider(widget.circleId),
                      ),
                    ),
                    data: (snapshot) => _ConversationList(
                      snapshot: snapshot,
                      onRefresh: _refresh,
                      onRetry: _retry,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: typingUsers.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                          key: const ValueKey<String>('realtime-typing'),
                          padding: const EdgeInsets.fromLTRB(
                            OrbitSpacing.md,
                            0,
                            OrbitSpacing.md,
                            OrbitSpacing.xs,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              typingUsers.length == 1
                                  ? 'Someone is typing…'
                                  : '${typingUsers.length} people are typing…',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: OrbitColors.textMuted),
                            ),
                          ),
                        ),
                ),
                MessageComposer(
                  onSend: _send,
                  onTypingChanged: _typing,
                  isSending: _sending,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _messageFor(Object error) {
    return switch (error) {
      OrbitApiException value => value.message,
      MessagingServiceException value => value.message,
      OrbitE2eeException value => value.message,
      StateError _ =>
        'A device encryption identity changed unexpectedly. Orbit stopped before trusting the new key.',
      _ => 'Orbit could not complete the encrypted messaging operation.',
    };
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({
    required this.snapshot,
    required this.onRefresh,
    required this.onRetry,
  });

  final ConversationSnapshot snapshot;
  final Future<void> Function() onRefresh;
  final Future<void> Function(LocalMessage message) onRetry;

  @override
  Widget build(BuildContext context) {
    if (snapshot.messages.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const <Widget>[
            SizedBox(height: 150),
            OrbitEmptyState(
              title: 'A private space for your Circle',
              message:
                  'Text is encrypted on your device before Orbit sends an opaque envelope to the server.',
            ),
          ],
        ),
      );
    }

    final reversed = snapshot.messages.reversed.toList(growable: false);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        reverse: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          OrbitSpacing.md,
          OrbitSpacing.md,
          OrbitSpacing.md,
          OrbitSpacing.lg,
        ),
        itemCount: reversed.length + 1,
        itemBuilder: (context, index) {
          if (index == reversed.length) {
            return Padding(
              padding: const EdgeInsets.only(bottom: OrbitSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: OrbitColors.success,
                  ),
                  const SizedBox(width: OrbitSpacing.xs),
                  Flexible(
                    child: Text(
                      'Protected by Orbit E2EE • ${snapshot.identityFingerprint}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: OrbitColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          final message = reversed[index];
          return MessageBubble(
            message: message,
            onRetry: message.status == LocalMessageStatus.failed
                ? () => onRetry(message)
                : null,
          );
        },
      ),
    );
  }
}
