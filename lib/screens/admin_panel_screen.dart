import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final _postController = TextEditingController();
  final _bannerController = TextEditingController();
  final _daysController = TextEditingController();
  final _eventTitleController = TextEditingController(); // حقل اسم الحدث الجديد
  final _newPinController = TextEditingController();
  
  File? _adminSelectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAdminImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _adminSelectedImage = File(image.path);
      });
    }
  }

  void _changePin() async {
    if (_newPinController.text.length >= 4) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_pin', _newPinController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير الرمز السري بنجاح')));
        _newPinController.clear();
      }
    }
  }

  void _showEditBannerDialog(int index, String currentText) {
    final editController = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('تعديل الإعلان المتحرك 📢', style: TextStyle(color: AppColors.accent)),
        content: TextField(
          controller: editController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'أدخل النص الجديد للإعلان...'),
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
                setState(() {});
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
      appBar: AppBar(title: const Text('البوابة الآمنة - لوحة التحكم')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // قسم إدارة الإعلان المتحرك المميز والترتيب الأعلى
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
                    label: const Text('إضافة الإعلان لشريط الأخبار', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      if (_bannerController.text.trim().isNotEmpty) {
                        widget.onAddBanner(_bannerController.text.trim());
                        _bannerController.clear();
                        setState(() {});
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
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                                  onPressed: () {
                                    widget.onDeleteBanner(index);
                                    setState(() {});
                                  },
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

            // إدارة العداد التنازلي مع إضافة اسم الحدث وأناقة العرض
            _buildCard(
              title: 'إدارة العداد التنازلي والحدث القادم ⏳',
              child: Column(
                children: [
                  TextField(
                    controller: _eventTitleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'اسم الحدث (مثلاً: امتحان الفاينال، موعد التسجيل)',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'عدد الأيام المتبقية',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                          onPressed: () {
                            int? days = int.tryParse(_daysController.text);
                            if (days != null) {
                              widget.onUpdateTimerDays(days);
                              _daysController.clear();
                              _eventTitleController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث العداد بنجاح')));
                            }
                          },
                          child: const Text('تشغيل وتحديث العداد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

            // إضافة منشور رسمي
            _buildCard(
              title: 'إضافة منشور رسمي (من المعرض) 📝',
              child: Column(
                children: [
                  TextField(
                    controller: _postController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'محتوى المنشور...',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_adminSelectedImage != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_adminSelectedImage!, height: 120, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: _pickAdminImage,
                    icon: const Icon(Icons.photo_library, color: AppColors.accent),
                    label: Text(_adminSelectedImage == null ? 'إرفاق صورة من المعرض' : 'تغيير الصورة', style: const TextStyle(color: AppColors.accent)),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                    onPressed: () {
                      if (_postController.text.isNotEmpty || _adminSelectedImage != null) {
                        widget.onAddPost(_postController.text, _adminSelectedImage);
                        _postController.clear();
                        setState(() => _adminSelectedImage = null);
                      }
                    },
                    child: const Text('نشر المنشور', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(color: Colors.white24),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.posts.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(widget.posts[index].content, maxLines: 1, style: const TextStyle(color: Colors.white)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            widget.onDeletePost(index);
                            setState(() {});
                          },
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // تغيير PIN
            _buildCard(
              title: 'تغيير الرمز السري للبوابة 🔐',
              child: Column(
                children: [
                  TextField(
                    controller: _newPinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'الرمز السري الجديد',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: _changePin, child: const Text('حفظ الرمز السري', style: TextStyle(color: AppColors.accent))),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
            const Divider(color: Colors.white10),
            child,
          ],
        ),
      ),
    );
  }
}
 
