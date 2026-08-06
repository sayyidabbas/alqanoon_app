import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class StudentForumScreen extends StatefulWidget {
  final String currentUserAccountName;
  final String currentUserAvatarUrl;
  final bool isAdmin;

  const StudentForumScreen({
    super.key,
    required this.currentUserAccountName,
    this.currentUserAvatarUrl = '',
    this.isAdmin = false,
  });

  @override
  State<StudentForumScreen> createState() => _StudentForumScreenState();
}

class _StudentForumScreenState extends State<StudentForumScreen> {
  bool _hasJoinedChat = false;
  bool _isCheckingJoinStatus = true;

  @override
  void initState() {
    super.initState();
    _checkJoinStatus();
  }

  Future<void> _checkJoinStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool joined = prefs.getBool('joined_forum_${widget.currentUserAccountName}') ?? false;
    setState(() {
      _hasJoinedChat = joined;
      _isCheckingJoinStatus = false;
    });
  }

  Future<void> _joinForum() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('joined_forum_${widget.currentUserAccountName}', true);
    setState(() {
      _hasJoinedChat = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingJoinStatus) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
      );
    }

    if (!_hasJoinedChat) {
      return JoinWelcomeScreen(onJoin: _joinForum);
    }

    return MainForumChatView(
      currentUserAccountName: widget.currentUserAccountName,
      currentUserAvatarUrl: widget.currentUserAvatarUrl,
      isAdmin: widget.isAdmin,
    );
  }
}

// ==========================================
// 1. شاشة الترحيب والانضمام المرة الأولى
// ==========================================
class JoinWelcomeScreen extends StatefulWidget {
  final VoidCallback onJoin;
  const JoinWelcomeScreen({super.key, required this.onJoin});

  @override
  State<JoinWelcomeScreen> createState() => _JoinWelcomeScreenState();
}

class _JoinWelcomeScreenState extends State<JoinWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // خلفية بتدرج إضاءة أنيق
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4AF37).withOpacity(0.15),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A1A1A),
                          border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.forum_rounded,
                          size: 70,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'مرحباً بك في الدردشة العامة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'مجتمعك الطلابي المباشر للنقاش وتبادل الملفات والاستفسارات باحترافية.',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      ElevatedButton(
                        onPressed: widget.onJoin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'انضم إلى الدردشة الآن',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ==========================================
// 2. الواجهة الرئيسية للدردشة (Main View)
// ==========================================
class MainForumChatView extends StatefulWidget {
  final String currentUserAccountName;
  final String currentUserAvatarUrl;
  final bool isAdmin;

  const MainForumChatView({
    super.key,
    required this.currentUserAccountName,
    required this.currentUserAvatarUrl,
    required this.isAdmin,
  });

  @override
  State<MainForumChatView> createState() => _MainForumChatViewState();
}

class _MainForumChatViewState extends State<MainForumChatView> with WidgetsBindingObserver {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? replyToMessage;
  bool _isChatDisabled = false;
  bool _isUserBanned = false;
  bool _isUploading = false;
  List<String> _bannedUsers = [];
  int _documentLimit = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setUserPresence(true);
    _listenToAdminSettings();
    _scrollController.addListener(_onScroll);
    _chatController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setUserPresence(false);
    _scrollController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setUserPresence(true);
    } else {
      _setUserPresence(false);
    }
  }

  void _setUserPresence(bool isOnline) {
    FirebaseFirestore.instance
        .collection('forum_presence')
        .doc(widget.currentUserAccountName)
        .set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
      'name': widget.currentUserAccountName,
    }, SetOptions(merge: true));
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
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      setState(() {
        _documentLimit += 20;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 2,
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFD4AF37),
              child: Icon(Icons.groups_rounded, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الدردشة العامة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('forum_presence')
                      .where('isOnline', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.data?.docs.length ?? 0;
                    return Text(
                      '$count متواجد الآن',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFD4AF37)),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFD4AF37)),
              onPressed: _showAdminOptionsMenu,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildPinnedMessageBanner(),
          if (_isUploading)
            const LinearProgressIndicator(backgroundColor: Colors.black, color: Color(0xFFD4AF37)),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('forum_chats')
                  .orderBy('timestamp', descending: true)
                  .limit(_documentLimit)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                }

                var docs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
    // ==========================================
  // 3. بناء فقاعة الرسالة واختيارات التحكم
  // ==========================================
  Widget _buildChatBubble(String docId, Map<String, dynamic> msg, bool isMe) {
    String formattedTime = _formatTime(msg['timestamp']);
    Map<String, dynamic> reactions = Map<String, dynamic>.from(msg['reactions'] ?? {});
    String avatarUrl = msg['senderAvatar'] ?? '';

    return GestureDetector(
      onLongPress: () => _showContextMenu(docId, msg, isMe),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF2A2A2A),
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        (msg['sender'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFD4AF37) : const Color(0xFF222222),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        msg['sender'] ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ),
                  if (msg['replyTo'] != null) _buildReplyContent(msg['replyTo'], isMe),
                  _buildMessageMediaContent(msg, isMe),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 9,
                          color: isMe ? Colors.black54 : Colors.white38,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 13,
                          color: (msg['isRead'] ?? false) ? Colors.blue.shade800 : Colors.black45,
                        ),
                      ]
                    ],
                  ),
                  if (reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        children: reactions.values
                            .map((e) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(e.toString(), style: const TextStyle(fontSize: 11)),
                                ))
                            .toList(),
                      ),
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyContent(Map<String, dynamic> reply, bool isMe) {
    return Container(
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border(right: BorderSide(color: isMe ? Colors.black54 : const Color(0xFFD4AF37), width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply['sender'] ?? '',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isMe ? Colors.black87 : const Color(0xFFD4AF37),
            ),
          ),
          Text(
            reply['text'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: isMe ? Colors.black87 : Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageMediaContent(Map<String, dynamic> msg, bool isMe) {
    String type = msg['type'] ?? 'text';
    String url = msg['mediaUrl'] ?? msg['text'] ?? '';

    switch (type) {
      case 'image':
        return GestureDetector(
          onTap: () => _openImageViewer(url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
              maxHeight: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Container(
                  height: 150,
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
                );
              },
            ),
          ),
        );
      case 'audio':
        return AudioBubblePlayer(url: url, isMe: isMe);
      case 'file':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file, color: isMe ? Colors.black : const Color(0xFFD4AF37)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  msg['fileName'] ?? 'مستند مرفق',
                  style: TextStyle(color: isMe ? Colors.black : Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      default:
        return Text(
          msg['text'] ?? '',
          style: TextStyle(
            color: isMe ? Colors.black : Colors.white,
            fontSize: 14,
            height: 1.3,
          ),
        );
    }
  }

  void _showContextMenu(String docId, Map<String, dynamic> msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
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
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.white),
              title: const Text('نسخ النص', style: TextStyle(color: Colors.white)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: msg['text'] ?? ''));
                Navigator.pop(context);
                _showSnackBar('تم نسخ النص');
              },
            ),
            if (isMe || widget.isAdmin)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('حذف الرسالة', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(docId);
                },
              ),
            if (widget.isAdmin)
              ListTile(
                leading: const Icon(Icons.push_pin, color: Color(0xFFD4AF37)),
                title: Text((msg['isPinned'] ?? false) ? 'إلغاء التثبيت' : 'تثبيت الرسالة', style: const TextStyle(color: Colors.white)),
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

  void _deleteMessage(String docId) {
    FirebaseFirestore.instance.collection('forum_chats').doc(docId).delete();
  }
    // ==========================================
  // 4. الرفع الحقيقي على Firebase Storage والإدخال
  // ==========================================
  Future<void> _pickAndUploadFile(String type) async {
    File? file;
    String fileName = '';

    if (type == 'image') {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) {
        file = File(picked.path);
        fileName = picked.name;
      }
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type == 'audio' ? FileType.audio : FileType.any,
      );
      if (result != null && result.files.single.path != null) {
        file = File(result.files.single.path!);
        fileName = result.files.single.name;
      }
    }

    if (file == null) return;

    setState(() => _isUploading = true);

    try {
      String storagePath = 'forum_media/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      Reference ref = FirebaseStorage.instance.ref().child(storagePath);
      UploadTask uploadTask = ref.putFile(file);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      _sendMessage(
        type: type,
        mediaUrl: downloadUrl,
        fileName: fileName,
      );
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء رفع الملف: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _sendMessage({String type = 'text', String? mediaUrl, String? fileName}) async {
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
          'senderAvatar': widget.currentUserAvatarUrl,
          'text': text,
          'mediaUrl': mediaUrl ?? '',
          'fileName': fileName ?? '',
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

  Widget _buildInputArea() {
    if (_isChatDisabled && !widget.isAdmin) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red.shade900.withOpacity(0.3),
        child: const Center(
          child: Text(
            'الإرسال مغلق حالياً بقرار من الإدارة',
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: const Color(0xFF1A1A1A),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: Color(0xFFD4AF37)),
              onPressed: _showAttachmentModal,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'اكتب رسالتك هنا...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFFD4AF37),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                onPressed: () => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _attachmentOption(Icons.image, 'صورة', () {
              Navigator.pop(context);
              _pickAndUploadFile('image');
            }),
            _attachmentOption(Icons.mic, 'تسجيل صوتي', () {
              Navigator.pop(context);
              _pickAndUploadFile('audio');
            }),
            _attachmentOption(Icons.insert_drive_file, 'مستند', () {
              Navigator.pop(context);
              _pickAndUploadFile('file');
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
            radius: 28,
            backgroundColor: const Color(0xFF2A2A2A),
            child: Icon(icon, color: const Color(0xFFD4AF37)),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.white)),
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
          color: const Color(0xFFD4AF37).withOpacity(0.15),
          child: Row(
            children: [
              const Icon(Icons.push_pin, size: 16, color: Color(0xFFD4AF37)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'مثبّت: ${pinnedData['text']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
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
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFFD4AF37)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: const Color(0xFF222222),
      child: Row(
        children: [
          const Icon(Icons.reply, color: Color(0xFFD4AF37), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'الرد على (${replyToMessage!['sender']}): ${replyToMessage!['text']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.white),
            onPressed: () => setState(() => replyToMessage = null),
          ),
        ],
      ),
    );
  }

  void _toggleReaction(String docId, Map<String, dynamic> reactions, String emoji) {
    String user = widget.currentUserAccountName;
    if (reactions[user] == emoji) {
      reactions.remove(user);
    } else {
      reactions[user] = emoji;
    }

    FirebaseFirestore.instance.collection('forum_chats').doc(docId).update({'reactions': reactions});
  }

  void _openImageViewer(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
          body: Center(child: InteractiveViewer(child: Image.network(url))),
        ),
      ),
    );
  }

  void _showAdminOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('لوحة تحكم الإدارة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const Divider(color: Colors.white10),
            ListTile(
              leading: Icon(_isChatDisabled ? Icons.lock_open : Icons.lock, color: const Color(0xFFD4AF37)),
              title: Text(_isChatDisabled ? 'تفعيل الدردشة للجميع' : 'قفل الدردشة', style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                FirebaseFirestore.instance.collection('chat_settings').doc('general').set({'isChatDisabled': !_isChatDisabled}, SetOptions(merge: true));
              },
            ),
          ],
        ),
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
}

// ==========================================
// مشغّل الصوتيات للرسائل الصوتية
// ==========================================
class AudioBubblePlayer extends StatefulWidget {
  final String url;
  final bool isMe;
  const AudioBubblePlayer({super.key, required this.url, required this.isMe});

  @override
  State<AudioBubblePlayer> createState() => _AudioBubblePlayerState();
}

class _AudioBubblePlayerState extends State<AudioBubblePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(UrlSource(widget.url));
      setState(() => _isPlaying = true);
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            size: 32,
            color: widget.isMe ? Colors.black : const Color(0xFFD4AF37),
          ),
          onPressed: _togglePlay,
        ),
        Text(
          'تسجيل صوتي',
          style: TextStyle(
            color: widget.isMe ? Colors.black : Colors.white,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
