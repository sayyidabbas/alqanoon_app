import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String userName;
  final String userHandle;
  final List<Map<String, dynamic>>? initialMessages;

  const ChatScreen({
    super.key,
    required this.userName,
    required this.userHandle,
    this.initialMessages,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late List<Map<String, dynamic>> _messages;

  @override
  void initState() {
    super.initState();
    _messages = widget.initialMessages != null 
        ? List<Map<String, dynamic>>.from(widget.initialMessages!) 
        : [];
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final now = DateTime.now();
    final timeStr = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    setState(() {
      _messages.add({
        'text': _messageController.text.trim(),
        'isMe': true,
        'time': timeStr,
      });
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
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
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'ابدأ المحادثة مع ${widget.userName} 👋',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['isMe'] ?? (msg['sender'] == 'me');
                      
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
                                msg['text'] ?? msg['message'] ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.black : Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                msg['time'] ?? '',
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
