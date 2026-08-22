import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

import '../constants/app_colors.dart';
import '../models/post_model.dart';

class AdminPanelScreen extends StatefulWidget {
  final List<PostModel> posts;
  final List<String> announcements;
  final Function(String content, File? imageFile) onAddPost;
  final Function(int index) onDeletePost;
  final Function(int index, String newContent) onEditPost;
  final Function(String) onAddBanner;
  final Function(int index) onDeleteBanner;
  final Function(int days) onUpdateTimerDays;
  final VoidCallback onDeleteTimer;

  const AdminPanelScreen({
    super.key,
    required this.posts,
    required this.announcements,
    required this.onAddPost,
    required this.onDeletePost,
    required this.onEditPost,
    required this.onAddBanner,
    required this.onDeleteBanner,
    required this.onUpdateTimerDays,
    required this.onDeleteTimer,
  });

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  // للتحكم بالنصوص
  final _bannerController = TextEditingController();
  final _daysController = TextEditingController();
  final _eventTitleController = TextEditingController();
  final _postContentController = TextEditingController();
  
  // للتحكم بالملفات والصور
  final List<File> _selectedImages = [];
  File? _selectedPdfFile;
  bool _isUploadingPost = false;

  @override
  void dispose() {
    _bannerController.dispose();
    _daysController.dispose();
    _eventTitleController.dispose();
    _postContentController.dispose();
    super.dispose();
  }

  // ==========================================
  // دوال إرسال الإشعارات للجميع (FCM HTTP v1)
  // ==========================================
  Future<String> _getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "law-platform-55632",
      "private_key_id": "ac701a7ebca252fc64d36be54d023db5d0a161e4",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDIJDxydIHAr26t\nNFeY0u2DiioV9Bi88CnjK4SOPbGrUvziA3jEq/sYBleFoIOs1Tl1un2EXTRk5t1t\nTWIrTIfJenBQ3tchi1YTg6MXn45rBMA0iaOCcN3XWC1b5Fdda1Eb1Ls+BwCbyU57\nUC4xMT9t+50xDCz1JKlo7z2e+Xk0fiDWAtVICsqmlOeBY+h+vK2s6gQ7iO28ssEC\nSERP2hujorDNIqH99ZfO5f/vJ3uDTruV5myy6PYMQOoQjahXdtl1QFQIh0J4M4zC\nEUbixpAKylGgs2bqCVJ4GvSAidrkIDucBtFkp1RFEsCU2cvyjVch6ECkn50nvuBr\nke71McfpAgMBAAECggEADiiUFyO7VyKCAaJJjR/k2hCg5A8x3dHeoLnAJaDjLAPR\nrHqC5WTmPT+bmvItRoGKEFRKU14VmgrEANq/1mDSXVQ6VFpDXVXiV7yRAdeRh2wd\nXcob5VsvMnAEO3M2o/72zLF6sotjxWGTGgGk1umNO25YozLhjlES4//Cu/eZlbcz\ndZiXptIyPtIKwfA82ThczLaA7zU+GU7yqiPTvF+1gU4ffOi3l8E05rv2JaVn9aZn\nYgyUIkoXM48XMkOpl8NEF0o/G2WEc8/m0F88tlkofG3krE3WOAiiYPx7YCNz6CVE\nGDUAYHazAAxXvdrGklC8sTMMM/1XpdtGI6YTafGSIQKBgQDrqsIG2swb2rZgJmxv\n7VSN+SmxLBe6qPlT5qiV+Pq5/i3sSZG7z787eXt2M3U7VaxG7XkaYHfB9Z7tReS8\nUCVv/7BJ1kzjWKZaLTm1yrl1bMLLj9MCvIuWzYgoGSWNFyotY11YjETUBl0wque5\naKSVYBU3ZTMjXMbGHkD8abiA8QKBgQDZaNE6BZxh59y62KecfS+GeIAc2mV9iM85\ngLLx31u8pKmGbzULpZa/SS3qkGrAqktrAub7cgAJYjHpDz9JLxF6i7o7OJW8i8x/\nOKsOo5P3iS2Fa4dPqG0akF3ofSgkdxpY9YbOD5V0WIgoYoLT9X8SLysgYbJ7vfhI\nTVT5jmo2eQKBgQCjRR4/WX5nHdOUMYqW0Lnv0luMH5wg+cgi1H6fyGsMSIjQVvfc\nQkWekr9yWJwzi1tbmFJ6b7MIcX61q+KYhH4rZd1gilOiflxhxUtiIxzxuXQLS41J\nLA8ZXzOhdCqL4SybXWfiXOuiaPZPLVh1H4ZG5tZMFpSjPzeHMpabSTNGQQKBgQDO\nrzc5Udw5t5PAjffKbbigvi4NQBL8JPPcVt3H0/AChwgjJdXoHKQTdh6QwHq8bykD\nst6kbNxcD14jkrs3d+fF+NAzPLgdZ0oiKF12rUweJ+t+y5r3v8b5WgXs4A8pm5EQ\nwVpGy8npscC/o+d8WgdT4kO9pSNpQFCpa9s85IdVAQKBgGKI/sfzF4trlxki4hJg\nH6+fZ8+4cXqvhVa5q5KA9coJCCTUVtf0QOvK7x+1XhzG8nYLDNWm7TI8KOB+Odzy\nrOZzRLzIov4aT0krufMQPPffCJqKO2KPk4+tAV4m3y2m9JI5sK5C+yVNLBXmiUA7\n0MRxpw7K4WevhGEoRGHxYIIs\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-fbsvc@law-platform-55632.iam.gserviceaccount.com",
      "client_id": "111366556927016010526",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40law-platform-55632.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    List<String> scopes = [
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    try {
      final auth.ServiceAccountCredentials credentials = auth.ServiceAccountCredentials.fromJson(serviceAccountJson);
      final auth.AutoRefreshingAuthClient client = await auth.clientViaServiceAccount(credentials, scopes);
      final accessToken = client.credentials.accessToken.data;
      client.close();
      return accessToken;
    } catch (e) {
      debugPrint("خطأ في الحصول على التوكن: $e");
      return '';
    }
  }

  Future<void> _sendNotificationToAll(String title, String body) async {
    final String serverToken = await _getAccessToken();
    if (serverToken.isEmpty) return;

    final String endpointFCM = 'https://fcm.googleapis.com/v1/projects/law-platform-55632/messages:send';

    final Map<String, dynamic> message = {
      'message': {
        'topic': 'all_users', 
        'notification': {
          'title': title,
          'body': body,
        },
        // 🔔 السر هنا! هذا الجزء يجبر نظام الأندرويد على إظهار الإشعار حتى لو كان التطبيق مغلقاً
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': 'high_importance_channel',
            'sound': 'default',
            'notification_priority': 'PRIORITY_MAX',
            'default_vibrate_timings': true
          }
        },
        'data': {
          'type': 'official_post',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK'
        }
      }
    };

    try {
      final response = await http.post(
        Uri.parse(endpointFCM),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverToken',
        },
        body: jsonEncode(message),
      );
      if (response.statusCode == 200) {
        debugPrint('✅ تم إرسال الإشعار للجميع بنجاح');
      } else {
        debugPrint('❌ فشل إرسال الإشعار: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في الاتصال أثناء إرسال الإشعار: $e');
    }
  }

  // ==========================================
  // دوال اختيار الملفات والصور المتعددة
  // ==========================================
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage(imageQuality: 50);
    
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((xFile) => File(xFile.path)));
      });
    }
  }

  Future<void> _pickPdfFile() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'PDFs',
        extensions: <String>['pdf'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

      if (file != null) {
        setState(() {
          _selectedPdfFile = File(file.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking PDF: $e');
    }
  }

  // ==========================================
  // دالة النشر في فايربيس و Supabase
  // ==========================================
  Future<void> _publishPost() async {
    final content = _postContentController.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty && _selectedPdfFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء كتابة نص أو إرفاق ملف/صورة')));
      return;
    }

    setState(() {
      _isUploadingPost = true;
    });

    List<String> uploadedImageUrls = [];
    String? fileUrl;
    String? fileName;

    try {
      // 1. رفع الصور المتعددة
      for (var img in _selectedImages) {
        final imgName = 'official_${DateTime.now().millisecondsSinceEpoch}_${_selectedImages.indexOf(img)}.jpg';
        await Supabase.instance.client.storage.from('pdfs').upload(imgName, img);
        final publicUrl = Supabase.instance.client.storage.from('pdfs').getPublicUrl(imgName);
        uploadedImageUrls.add(publicUrl);
      }

      // 2. رفع ملف PDF
      if (_selectedPdfFile != null) {
        fileName = 'official_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await Supabase.instance.client.storage.from('pdfs').upload(fileName, _selectedPdfFile!);
        fileUrl = Supabase.instance.client.storage.from('pdfs').getPublicUrl(fileName);
        
        String originalName = _selectedPdfFile!.path.split('/').last;
        if (originalName.isNotEmpty) {
          fileName = originalName;
        }
      }

      // 3. الحفظ في فايربيس (official_posts)
      Map<String, dynamic> postData = {
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'commentsCount': 0,
      };

      if (uploadedImageUrls.isNotEmpty) {
        if (uploadedImageUrls.length == 1) {
          postData['imageUrl'] = uploadedImageUrls.first; 
        } else {
          postData['imageUrls'] = uploadedImageUrls; 
        }
      }

      if (fileUrl != null) {
        postData['fileUrl'] = fileUrl;
        postData['fileName'] = fileName;
      }

      await FirebaseFirestore.instance.collection('official_posts').add(postData);

      // --- إرسال الإشعار بعد الحفظ بنجاح ---
      String notificationBody = content.isNotEmpty ? content : 'يوجد مرفق جديد للتبليغ الرسمي.';
      if (notificationBody.length > 50) {
        notificationBody = '${notificationBody.substring(0, 50)}...';
      }
      await _sendNotificationToAll('تبليغ رسمي جديد 📢', notificationBody);
      // ------------------------------------

      setState(() {
        _postContentController.clear();
        _selectedImages.clear();
        _selectedPdfFile = null;
        _isUploadingPost = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر التبليغ الرسمي وإرسال إشعار للطلاب بنجاح!')));
      }

    } catch (e) {
      setState(() {
        _isUploadingPost = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء النشر: $e')));
      }
    }
  }

  void _showEditBannerDialog(int index, String currentText) {
    final editController = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('تعديل الإعلان 📢', style: TextStyle(color: AppColors.accent)),
        content: TextField(
          controller: editController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'أدخل النص الجديد...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () {
              if (editController.text.isNotEmpty) {
                widget.onDeleteBanner(index);
                widget.onAddBanner(editController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('لوحة التحكم الرئيسية'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // =====================================
            // 1. قسم الإعلانات
            // =====================================
            _buildCard(
              title: 'إدارة شريط الإعلانات المتحرك 📢',
              child: Column(
                children: [
                  TextField(
                    controller: _bannerController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'اكتب نص الإعلان المتحرك الجديد...',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                    icon: const Icon(Icons.campaign, color: Colors.black),
                    label: const Text('إضافة الإعلان', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      if (_bannerController.text.trim().isNotEmpty) {
                        widget.onAddBanner(_bannerController.text.trim());
                        _bannerController.clear();
                      }
                    },
                  ),
                  const Divider(color: Colors.white24),
                  if (widget.announcements.isEmpty)
                    const Text('لا توجد إعلانات حالية', style: TextStyle(color: Colors.white38))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.announcements.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            title: Text(widget.announcements[index], style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 2),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppColors.accent, size: 20),
                                  onPressed: () => _showEditBannerDialog(index, widget.announcements[index]),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                  onPressed: () => widget.onDeleteBanner(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // =====================================
            // 2. قسم العداد التنازلي واسم الحدث
            // =====================================
            _buildCard(
              title: 'إدارة العداد التنازلي والحدث ⏳',
              child: Column(
                children: [
                  TextField(
                    controller: _eventTitleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'اسم الحدث (مثلاً: موعد الامتحانات)',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'عدد الأيام المتبقية للحدث',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                          onPressed: () async {
                            int? days = int.tryParse(_daysController.text);
                            if (days != null) {
                              // حفظ العداد مع اسم الحدث مباشرة في فايربيس لضمان التزامن
                              await FirebaseFirestore.instance.collection('settings').doc('timer').set({
                                'title': _eventTitleController.text.trim().isNotEmpty ? _eventTitleController.text.trim() : 'الحدث القادم',
                                'targetDate': Timestamp.fromDate(DateTime.now().add(Duration(days: days))),
                              });
                              _daysController.clear();
                              _eventTitleController.clear();
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تشغيل العداد بنجاح')));
                            }
                          },
                          child: const Text('تشغيل العداد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                        onPressed: widget.onDeleteTimer,
                        child: const Text('حذف العداد'),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // =====================================
            // 3. قسم إضافة منشور رسمي (متعدد الصور والملفات)
            // =====================================
            _buildCard(
              title: 'إضافة منشور رسمي 📝',
              child: Column(
                children: [
                  TextField(
                    controller: _postContentController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'اكتب محتوى التبليغ أو المنشور...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // عرض الصور المختارة
                  if (_selectedImages.isNotEmpty) ...[
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(_selectedImages[index], width: 100, height: 100, fit: BoxFit.cover),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () {
                                  setState(() { _selectedImages.removeAt(index); });
                                },
                              )
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // عرض الملف المختار
                  if (_selectedPdfFile != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_selectedPdfFile!.path.split('/').last, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis)),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.redAccent),
                            onPressed: () {
                              setState(() { _selectedPdfFile = null; });
                            },
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // أزرار الاختيار والنشر
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accent)),
                        onPressed: _pickImages,
                        icon: const Icon(Icons.image, color: AppColors.accent),
                        label: const Text('صور', style: TextStyle(color: AppColors.accent)),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                        onPressed: _pickPdfFile,
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                        label: const Text('ملف PDF', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: _isUploadingPost ? null : _publishPost,
                      child: _isUploadingPost 
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text('نشر التبليغ الرسمي', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),

                  const Divider(color: Colors.white24, height: 30),

                  // عرض التبليغات للحذف
                  const Text('التبليغات المنشورة مسبقاً:', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('official_posts').orderBy('timestamp', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const Text('لا توجد تبليغات رسمية', style: TextStyle(color: Colors.white54));

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          return Card(
                            color: Colors.white10,
                            child: ListTile(
                              title: Text(data['content'] ?? 'مرفقات', style: const TextStyle(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () {
                                  FirebaseFirestore.instance.collection('official_posts').doc(docs[index].id).delete();
                                },
                              ),
                            ),
                          );
                        },
                      );
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 16)),
            const Divider(color: Colors.white10, height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
