import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? replyToMessage;
  bool _isChatDisabled = false;
  bool _isUserBanned = false;
  List<String> _bannedUsers = [];
  
  int _documentLimit = 20;
  bool _isLoadingMore = false;
  
  @override
  void initState() {
    super.initState();
    _listenToAdminSettings();
    _scrollController.addListener(_onScroll);
    _chatController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _listenToAdminSettings() {
    FirebaseFirestore.instance
        .collection('chat_settings')
        .doc('general')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data()!;
        if (mounted) {
          setState(() {
            _isChatDisabled = data['isChatDisabled'] ?? false;
            _bannedUsers = List<String>.from(data['bannedUsers'] ?? []);
            _isUserBanned = _bannedUsers.contains(widget.currentUserAccountName);
          });
        }
      }
    });
  }

  void _onTextChanged() {
    bool isTyping = _chatController.text.isNotEmpty;
    FirebaseFirestore.instance
        .collection('chat_typing')
        .doc(widget.currentUserAccountName)
        .set({'isTyping': isTyping, 'sender': widget.currentUserAccountName});
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreMessages();
    }
  }

  void _loadMoreMessages() {
    if (!_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
        _documentLimit += 20;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showAdminOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'لوحة تحكم الإدارة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  _isChatDisabled ? Icons.lock_open : Icons.lock,
                  color: const Color(0xFFD4AF37),
                ),
                title: Text(_isChatDisabled ? 'تفعيل الإرسال للجميع' : 'إيقاف الإرسال (قفل الدردشة)'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleChatState(!_isChatDisabled);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('إدارة المستخدمين المحظورين'),
                onTap: () {
                  Navigator.pop(context);
                  _showBanUserDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleChatState(bool disable) {
    FirebaseFirestore.instance
        .collection('chat_settings')
        .doc('general')
        .set({'isChatDisabled': disable}, SetOptions(merge: true));
  }

  void _showBanUserDialog() {
    TextEditingController userController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حظر / إلغاء حظر مستخدم'),
        content: TextField(
          controller: userController,
          decoration: const InputDecoration(hintText: 'اسم المستخدم/الحساب'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              String name = userController.text.trim();
              if (name.isNotEmpty) {
                if (_bannedUsers.contains(name)) {
                  _bannedUsers.remove(name);
                } else {
                  _bannedUsers.add(name);
                }
                FirebaseFirestore.instance
                    .collection('chat_settings')
                    .doc('general')
                    .set({'bannedUsers': _bannedUsers}, SetOptions(merge: true));
                Navigator.pop(context);
              }
            },
            child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
    void _sendMessage({String type = 'text', String? mediaUrl}) async {
    if (_isChatDisabled && !widget.isAdmin) {
      _showSnackBar('الدردشة مغلقة حالياً من قبل الإدارة.');
      return;
    }
    if (_isUserBanned) {
      _showSnackBar('حسابك محظور من المشاركة في الدردشة.');
      return;
    }

    String text = _chatController.text.trim();
    if (text.isNotEmpty || mediaUrl != null) {
      _chatController.clear();

      try {
        await FirebaseFirestore.instance.collection('forum_chats').add({
          'sender': widget.currentUserAccountName,
          'text': mediaUrl ?? text,
          'type': type,
          'replyTo': replyToMessage != null
              ? {
                  'text': replyToMessage!['text'],
                  'sender': replyToMessage!['sender']
                }
              : null,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'reactions': {},
          'isPinned': false,
        });

        _scrollToBottom();
      } catch (e) {
        debugPrint("Error sending message: $e");
      }

      if (mounted) {
        setState(() {
          replyToMessage = null;
        });
      }
    }
  }

  void _toggleReaction(String docId, Map<String, dynamic> reactions, String emoji) {
    String user = widget.currentUserAccountName;
    if (reactions[user] == emoji) {
      reactions.remove(user);
    } else {
      reactions[user] = emoji;
    }

    FirebaseFirestore.instance
        .collection('forum_chats')
        .doc(docId)
        .update({'reactions': reactions});
  }

  void _showAttachmentModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 180,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _attachmentOption(Icons.image, 'صورة', () {
              Navigator.pop(context);
              _sendMessage(type: 'image', mediaUrl: 'https://via.placeholder.com/150');
            }),
            _attachmentOption(Icons.mic, 'تسجيل صوتي', () {
              Navigator.pop(context);
              _sendMessage(type: 'audio', mediaUrl: 'audio_file_url');
            }),
            _attachmentOption(Icons.insert_drive_file, 'مستند PDF', () {
              Navigator.pop(context);
              _sendMessage(type: 'file', mediaUrl: 'document_file_url');
            }),
          ],
        ),
      ),
    );
  }

  Widget _attachmentOption(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFD4AF37),
            child: Icon(icon, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) return '';
    DateTime dt = timestamp.toDate();
    int hourInt = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    String hour = hourInt.toString().padLeft(2, '0');
    String minute = dt.minute.toString().padLeft(2, '0');
    String period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدردشة العامة'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showAdminOptionsMenu,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildPinnedMessageBanner(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('forum_chats')
                  .orderBy('timestamp', descending: true)
                  .limit(_documentLimit)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                }

                var docs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, idx) {
                    var doc = docs[idx];
                    var msg = doc.data() as Map<String, dynamic>;
                    bool isMe = msg['sender'] == widget.currentUserAccountName;

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.startToEnd,
                      confirmDismiss: (direction) async {
                        setState(() {
                          replyToMessage = msg;
                        });
                        return false;
                      },
                      child: _buildChatBubble(doc.id, msg, isMe),
                    );
                  },
                );
              },
            ),
          ),
          _buildTypingIndicator(),
          if (replyToMessage != null) _buildReplyPreview(),
          _buildInputArea(),
        ],
      ),
    );
  }
    Widget _buildPinnedMessageBanner() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('forum_chats')
          .where('isPinned', isEqualTo: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        var pinnedData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFFD4AF37).withOpacity(0.2),
          child: Row(
            children: [
              const Icon(Icons.push_pin, size: 18, color: Color(0xFFD4AF37)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'مثبّت: ${pinnedData['text']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatBubble(String docId, Map<String, dynamic> msg, bool isMe) {
    String formattedTime = _formatTime(msg['timestamp']);
    Map<String, dynamic> reactions = Map<String, dynamic>.from(msg['reactions'] ?? {});

    return GestureDetector(
      onLongPress: () => _showContextMenu(docId, msg, isMe),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          margin: const EdgeInsets.only(bottom: 12),
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
                Text(
                  msg['sender'] ?? '',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              if (msg['replyTo'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'رد على (${msg['replyTo']['sender']}): ${msg['replyTo']['text']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.black87 : Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              ],
              const SizedBox(height: 2),
              if (msg['type'] == 'image')
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(msg['text'], height: 150, fit: BoxFit.cover),
                )
              else if (msg['type'] == 'audio')
                const Row(
                  children: [
                    Icon(Icons.play_arrow),
                    SizedBox(width: 8),
                    Text('رسالة صوتية'),
                  ],
                )
              else
                Text(
                  msg['text'] ?? '',
                  style: TextStyle(color: isMe ? Colors.black : Colors.white, fontSize: 14),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 9,
                      color: isMe ? Colors.black54 : Colors.white54,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all,
                      size: 14,
                      color: (msg['isRead'] ?? false) ? Colors.blue : Colors.black45,
                    ),
                  ]
                ],
              ),
              if (reactions.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: reactions.values.map((e) => Text(e.toString())).toList(),
                )
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(String docId, Map<String, dynamic> msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['❤️', '👍', '😂', '😮', '😢'].map((emoji) {
                return IconButton(
                  icon: Text(emoji, style: const TextStyle(fontSize: 24)),
                  onPressed: () {
                    Navigator.pop(context);
                    _toggleReaction(docId, Map<String, dynamic>.from(msg['reactions'] ?? {}), emoji);
                  },
                );
              }).toList(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('نسخ النص'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: msg['text'] ?? ''));
                Navigator.pop(context);
                _showSnackBar('تم نسخ النص');
              },
            ),
            if (widget.isAdmin)
              ListTile(
                leading: const Icon(Icons.push_pin),
                title: Text((msg['isPinned'] ?? false) ? 'إلغاء التثبيت' : 'تثبيت الرسالة'),
                onTap: () {
                  Navigator.pop(context);
                  FirebaseFirestore.instance
                      .collection('forum_chats')
                      .doc(docId)
                      .update({'isPinned': !(msg['isPinned'] ?? false)});
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade300,
      child: Row(
        children: [
          const Icon(Icons.reply, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'الرد على (${replyToMessage!['sender']}): ${replyToMessage!['text']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => replyToMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chat_typing').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        var typingUsers = snapshot.data!.docs
            .where((doc) => doc['isTyping'] == true && doc['sender'] != widget.currentUserAccountName)
            .map((doc) => doc['sender'])
            .toList();

        if (typingUsers.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${typingUsers.join(', ')} يكتب الآن...',
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    if (_isChatDisabled && !widget.isAdmin) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red.shade100,
        child: const Center(
          child: Text(
            'الإرسال مغلق حالياً بقرار من الإدارة',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.grey),
            onPressed: _showAttachmentModal,
          ),
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: const InputDecoration(
                hintText: 'اكتب رسالتك هنا...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFFD4AF37)),
            onPressed: () => _sendMessage(),
          ),
        ],
      ),
    );
  }
}
