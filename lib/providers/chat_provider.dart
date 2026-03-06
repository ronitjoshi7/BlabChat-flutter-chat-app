import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blab_chat/models/message.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final String chatId; // Unique doc ID for this 1-on-1 conversation
  final String otherUserId; // The other participant's UID

  List<Message> _messages = [];
  bool _isSending = false;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _subscription;

  ChatProvider({required this.chatId, required this.otherUserId}) {
    _listenToMessages();
  }

  // ── Getters ────────────────────────────────────────────────────────────────

  List<Message> get messages => _messages;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  String get currentUserId => _auth.currentUser!.uid;

  // ── Real-time listener ─────────────────────────────────────────────────────

  void _listenToMessages() {
    _subscription = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            _messages = snapshot.docs
                .map((doc) => Message.fromDoc(doc))
                .toList();
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Failed to load messages. Please try again.';
            notifyListeners();
          },
        );
  }

  // ── Send message ───────────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final message = Message(
        id: '', // Firestore will assign the ID
        senderId: currentUserId,
        text: trimmed,
        timestamp: DateTime.now(), // Local optimistic timestamp
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());

      // Also update the chat doc with a preview (useful for a chats list screen)
      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': trimmed,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'participants': [currentUserId, otherUserId],
      }, SetOptions(merge: true));
    } catch (e) {
      _errorMessage = 'Failed to send message. Please try again.';
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
