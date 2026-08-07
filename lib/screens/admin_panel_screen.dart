import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../models/post_model.dart';

class AdminPanelScreen extends StatefulWidget {
  final List<PostModel> posts;
  final List<String> announcements;
  final Function(String content, String? imageUrl) onAddPost;
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
  final _imageUrlController = TextEditingController();
  final _bannerController = TextEditingController();
  final _daysController = TextEditingController();
  final _newPinController = TextEditingController();

  void _changePin() async {
    if (_newPinController.text.length >= 4) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_pin', _newPinController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير الرمز السري')));
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
            // قسم العداد
            _buildCard(
              title: 'إدارة العداد التنازلي',
              child: Column(
                children: [
                  TextField(
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'أدخل عدد الأيام للعداد'),
                  ),
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
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: widget.onDeleteTimer,
                        child: const Text('حذف العداد'),
                      )
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // قسم المنشورات
            _buildCard(
              title: 'إضافة/إدارة المنشورات (صورة + نص)',
              child: Column(
                children: [
                  TextField(controller: _postController, maxLines: 2, decoration: const InputDecoration(hintText: 'محتوى المنشور')),
                  const SizedBox(height: 8),
                  TextField(controller: _imageUrlController, decoration: const InputDecoration(hintText: 'رابط الصورة (اختياري)')),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                    onPressed: () {
                      if (_postController.text.isNotEmpty) {
                        widget.onAddPost(_postController.text, _imageUrlController.text.isEmpty ? null : _imageUrlController.text);
                        _postController.clear();
                        _imageUrlController.clear();
                        setState(() {});
                      }
                    },
                    child: const Text('نشر جديد', style: TextStyle(color: Colors.black)),
                  ),
                  const Divider(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.posts.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(widget.posts[index].content, maxLines: 1),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.accent),
                              onPressed: () {
                                final editCtrl = TextEditingController(text: widget.posts[index].content);
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: AppColors.cardBg,
                                    title: const Text('تعديل المنشور'),
                                    content: TextField(controller: editCtrl),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          widget.onEditPost(index, editCtrl.text);
                                          Navigator.pop(context);
                                          setState(() {});
                                        },
                                        child: const Text('حفظ'),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                widget.onDeletePost(index);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // قسم الإعلانات
            _buildCard(
              title: 'إدارة الإعلانات المتحركة',
              child: Column(
                children: [
                  TextField(controller: _bannerController, decoration: const InputDecoration(hintText: 'نص الإعلان')),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                    onPressed: () {
                      if (_bannerController.text.isNotEmpty) {
                        widget.onAddBanner(_bannerController.text);
                        _bannerController.clear();
                        setState(() {});
                      }
                    },
                    child: const Text('إضافة إعلان', style: TextStyle(color: Colors.black)),
                  ),
                  const Divider(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.announcements.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(widget.announcements[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            widget.onDeleteBanner(index);
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

            // قسم تغيير PIN
            _buildCard(
              title: 'تغيير الرمز السري للبوابة',
              child: Column(
                children: [
                  TextField(controller: _newPinController, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'الرمز السري الجديد')),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: _changePin, child: const Text('حفظ الرمز السري الجديد')),
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
