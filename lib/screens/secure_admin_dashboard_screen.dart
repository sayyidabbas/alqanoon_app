import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../models/post_model.dart';

class AdminPanelScreen extends StatefulWidget {
  final List<PostModel> posts;
  final List<String> announcements;
  final Function(String, File?) onAddPost;
  final Function(int) onDeletePost;
  final Function(int, String) onEditPost;
  final Function(String) onAddBanner;
  final Function(int) onDeleteBanner;
  final Function(int) onUpdateTimerDays;
  final Function() onDeleteTimer;

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
  final TextEditingController _bannerController = TextEditingController();
  final TextEditingController _timerController = TextEditingController();
  
  // متغيرات إضافة المنشور
  final TextEditingController _postContentController = TextEditingController();
  final List<File> _selectedImages = [];
  File? _selectedPdfFile;
  bool _isUploadingPost = false;

  @override
  void dispose() {
    _bannerController.dispose();
    _timerController.dispose();
    _postContentController.dispose();
    super.dispose();
  }

  // ==========================================
  // دوال اختيار الملفات والصور
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
  // دالة نشر المنشور (صورة/صور/ملف/نص) لفايربيس
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
      // 1. رفع الصور إن وجدت
      for (var img in _selectedImages) {
        final imgName = 'official_${DateTime.now().millisecondsSinceEpoch}_${_selectedImages.indexOf(img)}.jpg';
        await Supabase.instance.client.storage.from('pdfs').upload(imgName, img); // استخدمنا مجلد pdfs مؤقتاً كونه متاحاً
        final publicUrl = Supabase.instance.client.storage.from('pdfs').getPublicUrl(imgName);
        uploadedImageUrls.add(publicUrl);
      }

      // 2. رفع الملف إن وجد
      if (_selectedPdfFile != null) {
        fileName = 'official_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await Supabase.instance.client.storage.from('pdfs').upload(fileName, _selectedPdfFile!);
        fileUrl = Supabase.instance.client.storage.from('pdfs').getPublicUrl(fileName);
        
        // محاولة استخراج اسم الملف الأصلي للعرض
        String originalName = _selectedPdfFile!.path.split('/').last;
        if (originalName.isNotEmpty) {
          fileName = originalName;
        }
      }

      // 3. الحفظ في فايربيس
      Map<String, dynamic> postData = {
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'commentsCount': 0,
      };

      if (uploadedImageUrls.isNotEmpty) {
        if (uploadedImageUrls.length == 1) {
          postData['imageUrl'] = uploadedImageUrls.first; // لصورة واحدة
        } else {
          postData['imageUrls'] = uploadedImageUrls; // لعدة صور
        }
      }

      if (fileUrl != null) {
        postData['fileUrl'] = fileUrl;
        postData['fileName'] = fileName;
      }

      await FirebaseFirestore.instance.collection('official_posts').add(postData);

      // تنظيف الحقول بعد النشر
      setState(() {
        _postContentController.clear();
        _selectedImages.clear();
        _selectedPdfFile = null;
        _isUploadingPost = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر التبليغ بنجاح!')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('لوحة التحكم الخاصة'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =====================================
            // 1. قسم الإعلانات المتحركة
            // =====================================
            _buildSectionHeader('إدارة شريط الإعلانات المتحرك 📢'),
            const SizedBox(height: 10),
            TextField(
              controller: _bannerController,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'اكتب نص الإعلان المتحرك الجديد...',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () {
                if (_bannerController.text.isNotEmpty) {
                  widget.onAddBanner(_bannerController.text.trim());
                  _bannerController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الإعلان')));
                }
              },
              icon: const Icon(Icons.campaign, color: Colors.black),
              label: const Text('إضافة الإعلان لشريط الأخبار', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('settings').doc('announcements').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('لا توجد إعلانات حالية', style: TextStyle(color: Colors.white54)));
                }
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final List texts = data['texts'] ?? [];
                if (texts.isEmpty) return const Center(child: Text('لا توجد إعلانات حالية', style: TextStyle(color: Colors.white54)));

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: texts.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(texts[index], style: const TextStyle(color: Colors.white), textAlign: TextAlign.right),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => widget.onDeleteBanner(index),
                      ),
                    );
                  },
                );
              }
            ),
            
            const Divider(color: Colors.white24, height: 40),

            // =====================================
            // 2. قسم العداد التنازلي
            // =====================================
            _buildSectionHeader('إدارة العداد التنازلي (بالأيام) ⏳'),
            const SizedBox(height: 10),
            TextField(
              controller: _timerController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'عدد الأيام للحدث القادم',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                  onPressed: () {
                    widget.onDeleteTimer();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إيقاف وحذف العداد')));
                  },
                  child: const Text('حذف العداد', style: TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                    onPressed: () {
                      if (_timerController.text.isNotEmpty) {
                        int? days = int.tryParse(_timerController.text);
                        if (days != null) {
                          widget.onUpdateTimerDays(days);
                          _timerController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تشغيل العداد بنجاح')));
                        }
                      }
                    },
                    child: const Text('تشغيل العداد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            
            const Divider(color: Colors.white24, height: 40),

            // =====================================
            // 3. قسم نشر التبليغات الرسمية
            // =====================================
            _buildSectionHeader('إضافة تبليغ أو منشور رسمي 📝'),
            const SizedBox(height: 10),
            TextField(
              controller: _postContentController,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.right,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'اكتب محتوى التبليغ أو المنشور...',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
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
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
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
                        setState(() {
                          _selectedPdfFile = null;
                        });
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
                  label: const Text('ملف', style: TextStyle(color: Colors.redAccent)),
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

            const Divider(color: Colors.white24, height: 40),

            // =====================================
            // 4. عرض التبليغات السابقة (للحذف/التعديل)
            // =====================================
            _buildSectionHeader('التبليغات المنشورة مسبقاً 📋'),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('official_posts').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('لا توجد تبليغات رسمية', style: TextStyle(color: Colors.white54)));

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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showEditPostDialog(docs[index].id, data['content'] ?? '');
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () {
                                widget.onDeletePost(index); // يحذف من فايربيس عبر home_screen
                              },
                            ),
                          ],
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
    );
  }

  void _showEditPostDialog(String docId, String currentContent) {
    final editController = TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('تعديل التبليغ ✏️', style: TextStyle(color: AppColors.accent)),
        content: TextField(
          controller: editController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'أدخل النص الجديد...',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () async {
              final newContent = editController.text.trim();
              if (newContent.isNotEmpty) {
                await FirebaseFirestore.instance.collection('official_posts').doc(docId).update({
                  'content': newContent,
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعديل التبليغ بنجاح!')));
                }
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: const TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
 
