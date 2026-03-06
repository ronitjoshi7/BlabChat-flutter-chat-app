import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blab_chat/providers/chat_provider.dart';
import 'package:blab_chat/models/message.dart';

// ── Entry point ───────────────────────────────────────────────────────────────
// Wrap ChatScreen in a ChangeNotifierProvider so the provider is scoped to
// this conversation only. Pass chatId and otherUserId from your navigation.
//
// Example navigation call:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => ChatScreenWrapper(
//       chatId: 'abc123',
//       otherUserId: 'uid_of_other_user',
//       otherUserName: 'Jane Doe',
//     ),
//   ));

class ChatScreenWrapper extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreenWrapper({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(chatId: chatId, otherUserId: otherUserId),
      child: ChatScreen(otherUserName: otherUserName),
    );
  }
}

// ── Main screen ───────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final String otherUserName;

  const ChatScreen({super.key, required this.otherUserName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  static const _brandColor = Color.fromARGB(255, 197, 67, 67);

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(ChatProvider provider) async {
    final text = _messageController.text;
    _messageController.clear();
    await provider.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _brandColor,
        foregroundColor: Colors.white,
        title: Text(
          widget.otherUserName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ── Error banner ───────────────────────────────────────────────────
          Consumer<ChatProvider>(
            builder: (_, provider, _) {
              if (provider.errorMessage == null) return const SizedBox.shrink();
              return MaterialBanner(
                content: Text(provider.errorMessage!),
                backgroundColor: Colors.red.shade100,
                actions: [
                  TextButton(onPressed: () {}, child: const Text('Dismiss')),
                ],
              );
            },
          ),

          // ── Message list ───────────────────────────────────────────────────
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (_, provider, _) {
                if (provider.messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nSay hello! 👋',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // Scroll to bottom when new messages arrive
                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    final isMe = message.senderId == provider.currentUserId;
                    return _MessageBubble(message: message, isMe: isMe);
                  },
                );
              },
            ),
          ),

          // ── Input bar ──────────────────────────────────────────────────────
          _InputBar(
            controller: _messageController,
            onSend: _handleSend,
            brandColor: _brandColor,
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  static const _brandColor = Color.fromARGB(255, 197, 67, 67);

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? _brandColor : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black45,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Input bar ──────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function(ChatProvider) onSend;
  final Color brandColor;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (_, provider, _) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Text field
                Expanded(
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    onSubmitted: (_) => onSend(provider),
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: provider.isSending
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 44,
                          height: 44,
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          key: const ValueKey('send'),
                          onPressed: () => onSend(provider),
                          style: IconButton.styleFrom(
                            backgroundColor: brandColor,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.send_rounded),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
