import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String userName;
  final String userHandle;
  final String? peerUid;
  final List<Map<String, dynamic>>? initialMessages;

  const ChatScreen({
    super.key,
    required this.userName,
    required this.userHandle,
    this.peerUid,
    this.initialMessages,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  String _getChatId() {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final peerId = widget.peerUid ?? widget.userHandle;
    List<String> ids = [myUid, peerId]..sort();
    return ids.join('_');
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _messageController.clear();

    final chatId = _getChatId();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': myUid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // تحديث المحادثة في الفايربيس
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'lastMessage': text,
      'lastUpdated': FieldValue.serverTimestamp(),
      'users': [myUid, widget.peerUid ?? widget.userHandle],
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final chatId = _getChatId();

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userName, style: const TextStyle(fontSize: 16)),
            Text('@${widget.userHandle}', style: const TextStyle(fontSize: 12, color: AppColors.accent)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'ابدأ المحادثة مع ${widget.userName} 👋',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final msg = docs[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == myUid;
                    final time = msg['timestamp'] != null
                        ? (msg['timestamp'] as Timestamp).toDate()
                        : DateTime.now();
                    final timeStr = "${time.hour}:${time.minute.toString().padLeft(2, '0')}";

                    return Align(
                      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.accent : AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                          children: [
                            Text(
                              msg['text'] ?? '',
                              style: TextStyle(
                                color: isMe ? Colors.black : Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: isMe ? Colors.black54 : Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // حقل إدخال الرسالة
          Container(
            padding: const EdgeInsets.all(8.0),
            color: AppColors.cardBg,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالة...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.accent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
