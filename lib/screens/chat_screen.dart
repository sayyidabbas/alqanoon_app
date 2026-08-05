import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentForumScreen extends StatefulWidget {
  final String currentUserAccountName;
  const StudentForumScreen({super.key, required this.currentUserAccountName});

  @override
  State<StudentForumScreen> createState() => _StudentForumScreenState();
}

class _StudentForumScreenState extends State<StudentForumScreen> {
  String activeChannel = '📢 الدردشة العامة';
  Map<String, dynamic>? replyToMessage;
  final TextEditingController _chatController = TextEditingController();

  void _sendMessage() async {
    if (_chatController.text.trim().isNotEmpty) {
      String text = _chatController.text.trim();
      _chatController.clear();

      try {
        await FirebaseFirestore.instance.collection('forum_chats').add({
          'channel': activeChannel,
          'sender': widget.currentUserAccountName,
          'text': text,
          'replyTo': replyToMessage != null ? replyToMessage!['text'] : null,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (e) {
        debugPrint("Error sending message: $e");
      }

      setState(() {
        replyToMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(activeChannel),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            color: Colors.grey.shade200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['📢 الدردشة العامة', '📚 تبادل الملازم', '❓ سؤال وجواب'].map((ch) {
                bool isSel = activeChannel == ch;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: ChoiceChip(
                    label: Text(ch, style: TextStyle(fontSize: 12, color: isSel ? Colors.black : Colors.grey.shade700, fontWeight: FontWeight.bold)),
                    selected: isSel,
                    selectedColor: const Color(0xFFD4AF37),
                    onSelected: (val) => setState(() => activeChannel = ch),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('forum_chats')
                  .where('channel', isEqualTo: activeChannel)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                }
                var docs = snapshot.data?.docs ?? [];
                var sortedDocs = docs.toList()
                  ..sort((a, b) {
                    var aTime = (a.data() as Map<String, dynamic>)['timestamp'] ?? 0;
                    var bTime = (b.data() as Map<String, dynamic>)['timestamp'] ?? 0;
                    return aTime.compareTo(bTime);
                  });

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sortedDocs.length,
                  itemBuilder: (context, idx) {
                    var msg = sortedDocs[idx].data() as Map<String, dynamic>;
                    bool isMe = msg['sender'] == widget.currentUserAccountName;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFD4AF37) : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: isMe ? const Radius.circular(14) : const Radius.circular(2),
                            bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(14),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(msg['sender'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                            if (msg['replyTo'] != null) ...[
                              Container(
                                padding: const EdgeInsets.all(6),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                child: Text('رد على: ${msg['replyTo']}', style: TextStyle(fontSize: 11, color: isMe ? Colors.black87 : Colors.white70, fontStyle: FontStyle.italic)),
                              )
                            ],
                            const SizedBox(height: 2),
                            Text(msg['text'] ?? '', style: TextStyle(color: isMe ? Colors.black : Colors.white, fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: const InputDecoration(hintText: 'اكتب رسالتك هنا...', border: InputBorder.none),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Color(0xFFD4AF37)), onPressed: _sendMessage),
              ],
            ),
          )
        ],
      ),
    );
  }
}
