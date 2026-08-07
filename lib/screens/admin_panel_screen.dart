import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';

class AdminPanelScreen extends StatefulWidget {
  final Function(String) onAddPost;
  final Function(String) onAddBanner;
  final Function(Duration) onUpdateTimer;

  const AdminPanelScreen({
    super.key,
    required this.onAddPost,
    required this.onAddBanner,
    required this.onUpdateTimer,
  });

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _postController = TextEditingController();
  final _bannerController = TextEditingController();
  final _hoursController = TextEditingController();
  final _newPinController = TextEditingController();

  void _changePin() async {
    if (_newPinController.text.length >= 4) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_pin', _newPinController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تغيير الرقم السري بنجاح')),
        );
        _newPinController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البوابة الآمنة - لوحة التحكم'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionCard(
              title: 'إضافة منشور جديد',
              child: Column(
                children: [
                  TextField(
                    controller: _postController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'اكتب تفاصيل المنشور هنا...'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                    onPressed: () {
                      if (_postController.text.isNotEmpty) {
                        widget.onAddPost(_postController.text);
                        _postController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر المشاركة')));
                      }
                    },
                    icon: const Icon(Icons.send, color: Colors.black),
                    label: const Text('نشر الان', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'إضافة إعلان متحرك جديد',
              child: Column(
                children: [
                  TextField(
                    controller: _bannerController,
                    decoration: const InputDecoration(hintText: 'عنوان الإعلان أو التنبيه...'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                    onPressed: () {
                      if (_bannerController.text.isNotEmpty) {
                        widget.onAddBanner(_bannerController.text);
                        _bannerController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الإعلان')));
                      }
                    },
                    icon: const Icon(Icons.add_alert, color: Colors.black),
                    label: const Text('إضافة إعلان', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'ضبط العداد التنازلي (بالساعات)',
              child: Column(
                children: [
                  TextField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'أدخل عدد الساعات القادمة للمؤتمر/الحدث'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                    onPressed: () {
                      int? hours = int.tryParse(_hoursController.text);
                      if (hours != null) {
                        widget.onUpdateTimer(Duration(hours: hours));
                        _hoursController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث العداد التنازلي')));
                      }
                    },
                    icon: const Icon(Icons.timer, color: Colors.black),
                    label: const Text('حفظ العداد', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'تغيير الرقم السري للبوابة',
              child: Column(
                children: [
                  TextField(
                    controller: _newPinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'الرمز السري الجديد (4 أرقام فأكثر)'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accent)),
                    onPressed: _changePin,
                    icon: const Icon(Icons.security, color: AppColors.accent),
                    label: const Text('تغيير الرمز السري', style: TextStyle(color: AppColors.accent)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accent)),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
