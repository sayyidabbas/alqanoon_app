import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentForumScreen extends StatefulWidget {
  final String currentUserAccountName;
  final bool isAdmin;

  const StudentForumScreen({
    super.key,
    required this.currentUserAccountName,
    this.isAdmin = false,
  });

  @override
  State<StudentForumScreen> createState() => _StudentForumScreenState();
}

class _StudentForumScreenState extends State<StudentForumScreen> {
  final TextEditingController _msgController = TextEditingController();

  void _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;
    String text = _msgController.text.trim();
    _msgController.clear();

    await FirebaseFirestore.instance.collection('forum_messages').add({
      'sender': widget.currentUserAccountName,
      'text': text,
      'isAdminMessage': widget.isAdmin,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _deleteMessage(String docId) async {
    await FirebaseFirestore.instance.collection('forum_messages').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('الدردشة العامة', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
            if (widget.isAdmin) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield, size: 14, color: Colors.redAccent),
                    SizedBox(width: 4),
                    Text('الأدمن', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ]
          ],
        ),
        backgroundColor: const Color(0xFF121216),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('forum_messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                }

                var docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(15),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['sender'] == widget.currentUserAccountName;
                    bool isAdminMsg = data['isAdminMessage'] ?? false;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAdminMsg
                              ? const Color(0xFF2C220E)
                              : (isMe ? const Color(0xFF1E1E24) : const Color(0xFF16161C)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isAdminMsg ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  data['sender'] ?? '',
                                  style: TextStyle(
                                    color: isAdminMsg ? const Color(0xFFD4AF37) : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.isAdmin) ...[
                                  const SizedBox(width: 10),
                                  InkWell(
                                    onTap: () => _deleteMessage(docs[index].id),
                                    child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                                  ),
                                ]
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(data['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
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
            padding: const EdgeInsets.all(10),
            color: const Color(0xFF121216),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالتك هنا...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1E1E24),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFFD4AF37),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.black),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
