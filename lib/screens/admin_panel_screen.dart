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

      setState(() {
        _postContentController.clear();
        _selectedImages.clear();
        _selectedPdfFile = null;
        _isUploadingPost = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر التبليغ الرسمي بنجاح!')));
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
 
