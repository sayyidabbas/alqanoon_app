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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البوابة الآمنة - لوحة التحكم')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // إدارة العداد
            _buildCard(
              title: 'إدارة العداد التنازلي (بالأيام)',
              child: Column(
                children: [
                  TextField(controller: _daysController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'عدد الأيام للحدث القادم')),
                  const SizedBox(height: 10),
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
                            }
                          },
                          child: const Text('تشغيل العداد', style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: Colors.red), onPressed: widget.onDeleteTimer, child: const Text('حذف العداد')),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // إضافة منشور مع رفعه حصراً من المعرض
            _buildCard(
              title: 'إضافة منشور جديد (من المعرض)',
              child: Column(
                children: [
                  TextField(controller: _postController, maxLines: 2, decoration: const InputDecoration(hintText: 'محتوى المنشور...')),
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
                  const Divider(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.posts.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(widget.posts[index].content, maxLines: 1),
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
              title: 'تغيير الرمز السري للبوابة',
              child: Column(
                children: [
                  TextField(controller: _newPinController, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'الرمز السري الجديد')),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: _changePin, child: const Text('حفظ الرمز السري')),
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
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }
}
