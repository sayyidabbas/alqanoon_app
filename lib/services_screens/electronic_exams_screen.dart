import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';

// ==========================================
// دوال مساعدة عامة
// ==========================================

// دالة إرسال إشعارات داخل التطبيق
Future<void> sendInAppNotification(String userId, String title, String body) async {
  if (userId.isEmpty) return;
  await FirebaseFirestore.instance.collection('market_notifications').add({
    'userId': userId,
    'title': title,
    'body': body,
    'isRead': false,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

// دالة مساعدة لعرض غلاف الكتاب
Widget _buildBookCover(String imageUrl, {double? width, double? height, BorderRadius? borderRadius}) {
  if (imageUrl == 'default' || imageUrl.isEmpty) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
      child: const Icon(Icons.menu_book_rounded, size: 40, color: Colors.white54),
    );
  }

  Widget imageContent;
  if (imageUrl.startsWith('data:image')) {
    final base64Str = imageUrl.split(',').last;
    imageContent = Image.memory(
      base64Decode(base64Str),
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.red),
    );
  } else {
    imageContent = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.red),
    );
  }

  return ClipRRect(
    borderRadius: borderRadius ?? BorderRadius.zero,
    child: imageContent,
  );
}

// دالة ذكية لفتح الروابط (واتساب / تليجرام)
Future<void> _launchContactUrl(BuildContext context, String type, String contactInfo) async {
  String url = '';
  if (type == 'whatsapp') {
    String cleanPhone = contactInfo.replaceAll(RegExp(r'[^\d+]'), '');
    url = 'https://wa.me/$cleanPhone';
  } else if (type == 'telegram') {
    String cleanTg = contactInfo.replaceAll('@', '').trim();
    url = 'https://t.me/$cleanTg';
  }

  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح التطبيق، تأكد من صحة البيانات.')));
    }
  }
}

// ==========================================
// الشاشة الرئيسية للسوق القانوني
// ==========================================

class ElectronicExamsScreen extends StatefulWidget {
  const ElectronicExamsScreen({super.key});

  @override
  State<ElectronicExamsScreen> createState() => _ElectronicExamsScreenState();
}

class _ElectronicExamsScreenState extends State<ElectronicExamsScreen> {
  String get _userAdminKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'is_admin_unlocked_market_$uid';
  }

  Future<void> _handleAdminAccess(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool isAdminUnlocked = prefs.getBool(_userAdminKey) ?? false;

    if (isAdminUnlocked) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMarketDashboard()));
    } else {
      _showPasswordDialog(prefs);
    }
  }

  void _showPasswordDialog(SharedPreferences prefs) {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text('البوابة الآمنة للإدارة', textAlign: TextAlign.right, style: TextStyle(color: Colors.amber)),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'أدخل كلمة السر', hintStyle: TextStyle(color: Colors.white54)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () async {
              final doc = await FirebaseFirestore.instance.collection('settings').doc('admin_market').get();
              String currentPin = '1234';
              if (doc.exists && doc.data()!.containsKey('pin')) {
                currentPin = doc.data()!['pin'].toString();
              }
              
              if (passwordController.text.trim() == currentPin) {
                await prefs.setBool(_userAdminKey, true);
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMarketDashboard()));
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة السر غير صحيحة!')));
                }
              }
            },
            child: const Text('دخول', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('مكتبة الحقوق التفاعلية', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          // أيقونة الإشعارات التفاعلية
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('market_notifications')
                .where('userId', isEqualTo: uid)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              bool hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded, color: Colors.white),
                    tooltip: 'الإشعارات',
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                  if (hasUnread)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_rounded, color: Colors.white),
            tooltip: 'مشترياتي ومبيعاتي',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserMarketProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.amber),
            tooltip: 'البوابة الآمنة',
            onPressed: () => _handleAdminAccess(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, Color(0xFF0A0E21)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_stories_rounded, size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              const Text(
                'السوق القانوني للكتب',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                'بيع، شراء، وتبادل الكتب القانونية بين طلبة كلية الحقوق بسهولة وأمان.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 50),
              _buildMainButton(
                context,
                title: '📚 عرض كتابك',
                subtitle: 'قم ببيع أو التبرع بكتبك المستعملة',
                color: Colors.amber,
                textColor: AppColors.primary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectStageScreen(isAddingBook: true))),
              ),
              const SizedBox(height: 20),
              _buildMainButton(
                context,
                title: '📖 الكتب المعروضة',
                subtitle: 'تصفح الكتب المتاحة للشراء أو المجانية',
                color: Colors.white,
                textColor: AppColors.primary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectStageScreen(isAddingBook: false))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton(BuildContext context, {required String title, required String subtitle, required Color color, required Color textColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      splashColor: Colors.grey.withOpacity(0.3),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 5),
            Text(subtitle, style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// شاشة الإشعارات للمستخدم
// ==========================================
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    // بمجرد فتح الشاشة، نجعل كل الإشعارات مقروءة
    FirebaseFirestore.instance.collection('market_notifications')
      .where('userId', isEqualTo: uid)
      .where('isRead', isEqualTo: false)
      .get().then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({'isRead': true});
        }
      });

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(title: const Text('الإشعارات'), backgroundColor: AppColors.primary),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('market_notifications')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final notifs = snapshot.data!.docs;

          if (notifs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded, size: 80, color: Colors.white24),
                  SizedBox(height: 10),
                  Text('لا توجد إشعارات حالياً', style: TextStyle(color: Colors.white54, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifs.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final data = notifs[index].data() as Map<String, dynamic>;
              return Card(
                color: const Color(0xFF1E2235),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.notifications_active, color: AppColors.primary)),
                  title: Text(data['title'] ?? '', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text(data['body'] ?? '', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// اختيار المرحلة الدراسية 
// ==========================================

class SelectStageScreen extends StatelessWidget {
  final bool isAddingBook;
  const SelectStageScreen({super.key, required this.isAddingBook});

  final List<String> stages = const ['المرحلة الأولى', 'المرحلة الثانية', 'المرحلة الثالثة', 'المرحلة الرابعة'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: Text(isAddingBook ? 'اختر مرحلة الكتاب' : 'تصفح حسب المرحلة'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stages.length,
        itemBuilder: (context, index) {
          return Card(
            color: const Color(0xFF1E2235),
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Colors.amber.shade100,
                child: Text('${index + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              title: Text(stages[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white), textAlign: TextAlign.right),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
              onTap: () {
                if (isAddingBook) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddBookFormScreen(stageIndex: index + 1, stageName: stages[index])));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BrowseSubjectsScreen(stageIndex: index + 1, stageName: stages[index])));
                }
              },
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 1. مسار البائع (إضافة كتاب)
// ==========================================

class AddBookFormScreen extends StatefulWidget {
  final int stageIndex;
  final String stageName;
  const AddBookFormScreen({super.key, required this.stageIndex, required this.stageName});

  @override
  State<AddBookFormScreen> createState() => _AddBookFormScreenState();
}

class _AddBookFormScreenState extends State<AddBookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _priceController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _telegramController = TextEditingController();

  String? _selectedSubject;
  bool _isFree = false;
  File? _imageFile;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 30);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _submitBook() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار المادة الدراسية')));
      return;
    }
    if (_whatsappController.text.trim().isEmpty && _telegramController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال وسيلة تواصل واحدة على الأقل')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: Color(0xFF1E2235),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.amber),
            SizedBox(height: 20),
            Text('جاري معالجة ورفع كتابك...', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_uid';
      String imageUrl = 'default';

      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final base64String = base64Encode(bytes);
        imageUrl = 'data:image/jpeg;base64,$base64String';
      }
      
      await FirebaseFirestore.instance.collection('book_market').add({
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim(),
        'stageIndex': widget.stageIndex,
        'stageName': widget.stageName,
        'subjectName': _selectedSubject,
        'isFree': _isFree,
        'price': _isFree ? 0 : int.tryParse(_priceController.text.trim()) ?? 0,
        'whatsapp': _whatsappController.text.trim(),
        'telegram': _telegramController.text.trim(),
        'sellerUid': uid,
        'buyerUid': null,
        'buyerName': null,
        'buyerContact': null,
        'status': 'pending',
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); // إغلاق التحميل
        Navigator.pop(context); // العودة
        Navigator.pop(context); // العودة للرئيسية
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1E2235),
            title: const Text('🎉 تم الإرسال بنجاح', textAlign: TextAlign.right, style: TextStyle(color: Colors.amber)),
            content: const Text('تم إرسال كتابك للإدارة للمراجعة.\nسيصلك إشعار فور الموافقة عليه.', textAlign: TextAlign.right, style: TextStyle(color: Colors.white)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً', style: TextStyle(color: Colors.amber)))],
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
  }

  InputDecoration _customInputDeco(String label, {IconData? icon, Color? iconColor, String? prefixText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: icon != null ? Icon(icon, color: iconColor) : null,
      prefixText: prefixText,
      prefixStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF1E2235),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(title: Text('عرض كتاب - ${widget.stageName}'), backgroundColor: AppColors.primary),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  width: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2235),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2, style: BorderStyle.solid),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: Colors.amber, size: 40),
                            SizedBox(height: 8),
                            Text('أضف الغلاف', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text('المعلومات الأساسية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber), textAlign: TextAlign.right),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titleController,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white),
              decoration: _customInputDeco('اسم الكتاب'),
              validator: (v) => v!.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _authorController,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white),
              decoration: _customInputDeco('اسم المؤلف'),
              validator: (v) => v!.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 15),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('market_settings').doc('stage_${widget.stageIndex}').collection('subjects').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator(color: Colors.amber);
                final subjects = snapshot.data!.docs.map((e) => e['name'] as String).toList();
                if (subjects.isEmpty) return const Text('لا توجد مواد مضافة لهذه المرحلة من قبل الإدارة', style: TextStyle(color: Colors.red), textAlign: TextAlign.right);
                
                return DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  dropdownColor: const Color(0xFF1E2235),
                  style: const TextStyle(color: Colors.white),
                  decoration: _customInputDeco('اختر المادة الدراسية'),
                  items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, textAlign: TextAlign.right))).toList(),
                  onChanged: (v) => setState(() => _selectedSubject = v),
                );
              },
            ),
            
            const SizedBox(height: 20),
            const Text('نوع العرض', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber), textAlign: TextAlign.right),
            Theme(
              data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.white54),
              child: Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      activeColor: Colors.amber,
                      title: const Text('بمبلغ مالي', textAlign: TextAlign.right, style: TextStyle(color: Colors.white)),
                      value: false,
                      groupValue: _isFree,
                      onChanged: (v) => setState(() => _isFree = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      activeColor: Colors.amber,
                      title: const Text('مجاني (خيري)', textAlign: TextAlign.right, style: TextStyle(color: Colors.white)),
                      value: true,
                      groupValue: _isFree,
                      onChanged: (v) => setState(() => _isFree = v!),
                    ),
                  ),
                ],
              ),
            ),
            if (!_isFree) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white),
                decoration: _customInputDeco('السعر (بالدينار العراقي)', prefixText: 'د.ع '),
                validator: (v) => v!.isEmpty ? 'يرجى إدخال السعر' : null,
              ),
            ],

            const SizedBox(height: 20),
            const Text('معلومات التواصل (أدخل واحدة على الأقل)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber), textAlign: TextAlign.right),
            const SizedBox(height: 10),
            TextFormField(
              controller: _whatsappController,
              keyboardType: TextInputType.phone,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white),
              decoration: _customInputDeco('رقم الواتساب', icon: Icons.phone, iconColor: Colors.green),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _telegramController,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white),
              decoration: _customInputDeco('معرف التليجرام (بدون @)', icon: Icons.send, iconColor: Colors.blue),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: _submitBook,
              child: const Text('عرض الكتاب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. مسار المشتري (تصفح الكتب والتفاصيل)
// ==========================================

class BrowseSubjectsScreen extends StatelessWidget {
  final int stageIndex;
  final String stageName;
  const BrowseSubjectsScreen({super.key, required this.stageIndex, required this.stageName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(title: Text('مواد $stageName'), backgroundColor: AppColors.primary),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('market_settings').doc('stage_$stageIndex').collection('subjects').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('لا توجد مواد مضافة', style: TextStyle(color: Colors.white54)));

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final subjectName = docs[index]['name'];
              return Card(
                color: const Color(0xFF1E2235),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(subjectName, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                  leading: const Icon(Icons.menu_book, color: Colors.amber),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BooksListScreen(stageIndex: stageIndex, subjectName: subjectName))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BooksListScreen extends StatelessWidget {
  final int stageIndex;
  final String subjectName;
  const BooksListScreen({super.key, required this.stageIndex, required this.subjectName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(title: Text('كتب $subjectName'), backgroundColor: AppColors.primary),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('book_market')
            .where('stageIndex', isEqualTo: stageIndex)
            .where('subjectName', isEqualTo: subjectName)
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('حدث خطأ في جلب البيانات', style: TextStyle(color: Colors.white)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
          
          final books = snapshot.data!.docs.toList();
          books.sort((a, b) {
            Timestamp t1 = a['createdAt'] as Timestamp? ?? Timestamp.now();
            Timestamp t2 = b['createdAt'] as Timestamp? ?? Timestamp.now();
            return t2.compareTo(t1); 
          });

          if (books.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books_rounded, size: 80, color: Colors.white24),
                  SizedBox(height: 10),
                  Text('لا توجد كتب معروضة لهذه المادة حالياً', style: TextStyle(fontSize: 16, color: Colors.white54)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final data = books[index].data() as Map<String, dynamic>;
              final bookId = books[index].id;
              final isFree = data['isFree'] ?? false;
              final imageUrl = data['imageUrl'] ?? 'default';

              return Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.only(bottom: 15),
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailsScreen(bookId: bookId, bookData: data))),
                  child: Row(
                    children: [
                      _buildBookCover(
                        imageUrl,
                        width: 100,
                        height: 130,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
                              const SizedBox(height: 5),
                              Text('المؤلف: ${data['author']}', style: const TextStyle(color: Colors.black54), textAlign: TextAlign.right),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isFree ? Colors.green.shade100 : Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isFree ? '🎁 مجاني' : '💰 ${data['price']} د.ع',
                                  style: TextStyle(color: isFree ? Colors.green.shade800 : Colors.orange.shade800, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BookDetailsScreen extends StatelessWidget {
  final String bookId;
  final Map<String, dynamic> bookData;

  const BookDetailsScreen({super.key, required this.bookId, required this.bookData});

  void _showPurchaseDialog(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    if (uid == bookData['sellerUid']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكنك طلب شراء كتابك الخاص!')));
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final contactController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2235),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('إتمام طلب الكتاب', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber)),
              const SizedBox(height: 10),
              const Text('يرجى كتابة اسمك ووسيلة تواصل ليتمكن البائع من مراسلتك.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.right),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'الاسم الكريم',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true, fillColor: AppColors.primary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: contactController,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف أو يوزر التليجرام',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true, fillColor: AppColors.primary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب للتواصل' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx); 
                      
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const AlertDialog(
                          backgroundColor: Color(0xFF1E2235),
                          content: Row(
                            children: [
                              CircularProgressIndicator(color: Colors.amber),
                              SizedBox(width: 20),
                              Text('جاري إرسال طلبك للبائع...', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      );

                      // إرسال الإشعار للبائع
                      await sendInAppNotification(bookData['sellerUid'], 'طلب شراء جديد! 🎉', 'يرغب ${nameController.text.trim()} بشراء كتابك: ${bookData['title']}');

                      await FirebaseFirestore.instance.collection('book_market').doc(bookId).update({
                        'status': 'reserved',
                        'buyerUid': uid,
                        'buyerName': nameController.text.trim(),
                        'buyerContact': contactController.text.trim(),
                      });

                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).pop(); // إغلاق التحميل
                        Navigator.pop(context); // الرجوع لقائمة الكتب
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الإرسال! سيصل للبائع إشعار وسيتم التواصل معك قريباً.')));
                      }
                    }
                  },
                  child: const Text('تأكيد وإرسال الطلب', style: TextStyle(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFree = bookData['isFree'] ?? false;
    final imageUrl = bookData['imageUrl'] ?? 'default';

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(title: const Text('تفاصيل الكتاب'), backgroundColor: AppColors.primary),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(
              child: _buildBookCover(
                imageUrl,
                width: 150,
                height: 220,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(bookData['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber), textAlign: TextAlign.right),
            const SizedBox(height: 10),
            Text('المؤلف: ${bookData['author']}', style: const TextStyle(fontSize: 18, color: Colors.white70), textAlign: TextAlign.right),
            const Divider(height: 30, thickness: 1, color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isFree ? 'مجاني' : '${bookData['price']} د.ع', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isFree ? Colors.green : Colors.orange)),
                const Text('السعر:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('المادة الدراسية:', style: TextStyle(fontSize: 16, color: Colors.white54), textAlign: TextAlign.right),
            Text('${bookData['stageName']} - ${bookData['subjectName']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.right),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                icon: const Icon(Icons.shopping_cart, color: AppColors.primary),
                label: Text(isFree ? 'طلب الحصول على الكتاب مجاناً' : 'طلب شراء الكتاب', style: const TextStyle(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.bold)),
                onPressed: () => _showPurchaseDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. ملف الطالب (مشترياتي ومبيعاتي)
// ==========================================

class UserMarketProfileScreen extends StatelessWidget {
  const UserMarketProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          title: const Text('ملفي في السوق'),
          backgroundColor: AppColors.primary,
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'طلبات الشراء (مشترياتي)'),
              Tab(text: 'كتبي المعروضة (مبيعاتي)'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BuyerRequestsTab(),
            SellerBooksTab(),
          ],
        ),
      ),
    );
  }
}

class SellerBooksTab extends StatelessWidget {
  const SellerBooksTab({super.key});

  void _acceptRequest(BuildContext context, String bookId, String buyerUid, String bookTitle) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const AlertDialog(
      backgroundColor: Color(0xFF1E2235),
      content: Row(
        children: [
          CircularProgressIndicator(color: Colors.amber),
          SizedBox(width: 20),
          Text('جاري التأكيد...', style: TextStyle(color: Colors.white)),
        ],
      ),
    ));
    
    await FirebaseFirestore.instance.collection('book_market').doc(bookId).update({'status': 'sold'});
    await sendInAppNotification(buyerUid, 'تم تأكيد البيع 🤝', 'وافق البائع على تسليمك كتاب: $bookTitle');

    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('book_market').where('sellerUid', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        
        final books = snapshot.data!.docs.toList();
        books.sort((a, b) {
          Timestamp t1 = a['createdAt'] as Timestamp? ?? Timestamp.now();
          Timestamp t2 = b['createdAt'] as Timestamp? ?? Timestamp.now();
          return t2.compareTo(t1); 
        });

        if (books.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront_rounded, size: 80, color: Colors.white24),
                SizedBox(height: 10),
                Text('لم تقم بعرض أي كتب.', style: TextStyle(color: Colors.white54, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final data = books[index].data() as Map<String, dynamic>;
            final status = data['status'];
            String statusText = '';
            Color statusColor = Colors.grey;

            if (status == 'pending') { statusText = 'قيد المراجعة لدى الإدارة ⏳'; statusColor = Colors.orange; }
            else if (status == 'approved') { statusText = 'معروض في السوق ✅'; statusColor = Colors.blue; }
            else if (status == 'reserved') { statusText = '🎉 يوجد مشتري مهتم!'; statusColor = Colors.red; }
            else if (status == 'sold') { statusText = 'تم البيع بنجاح 🤝'; statusColor = Colors.green; }
            else if (status == 'rejected') { statusText = 'تم رفض الكتاب ❌'; statusColor = Colors.black; }

            return Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('الكتاب: ${data['title']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                    const SizedBox(height: 5),
                    Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 15)),
                    
                    if (status == 'reserved') ...[
                      const Divider(color: Colors.black12, thickness: 1, height: 20),
                      const Text('معلومات المشتري (تواصل معه للاتفاق):', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text('الاسم: ${data['buyerName'] ?? 'غير معروف'}', style: const TextStyle(fontSize: 15, color: Colors.black87)),
                      Text('الحساب / الرقم: ${data['buyerContact'] ?? 'غير متوفر'}', style: const TextStyle(fontSize: 15, color: Colors.blue, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          onPressed: () => _acceptRequest(context, books[index].id, data['buyerUid'], data['title']),
                          child: const Text('تأكيد إتمام البيع 🤝', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      )
                    ]
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class BuyerRequestsTab extends StatelessWidget {
  const BuyerRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('book_market').where('buyerUid', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        
        final books = snapshot.data!.docs.toList();
        books.sort((a, b) {
          Timestamp t1 = a['createdAt'] as Timestamp? ?? Timestamp.now();
          Timestamp t2 = b['createdAt'] as Timestamp? ?? Timestamp.now();
          return t2.compareTo(t1); 
        });

        if (books.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_rounded, size: 80, color: Colors.white24),
                SizedBox(height: 10),
                Text('ليس لديك طلبات شراء حالياً.', style: TextStyle(color: Colors.white54, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final data = books[index].data() as Map<String, dynamic>;
            final status = data['status'];
            
            if (status == 'sold') {
              return Card(
                color: Colors.green.shade50,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('✅ تمت الموافقة على طلبك: ${data['title']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      const SizedBox(height: 10),
                      const Text('تواصل مع البائع لإتمام الاستلام:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if ((data['whatsapp'] ?? '').isNotEmpty)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
                              icon: const Icon(Icons.phone, color: Colors.white),
                              label: const Text('واتساب', style: TextStyle(color: Colors.white)),
                              onPressed: () => _launchContactUrl(context, 'whatsapp', data['whatsapp']),
                            ),
                          if ((data['telegram'] ?? '').isNotEmpty)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
                              icon: const Icon(Icons.send, color: Colors.white),
                              label: const Text('تليجرام', style: TextStyle(color: Colors.white)),
                              onPressed: () => _launchContactUrl(context, 'telegram', data['telegram']),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(data['title'] ?? '', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('بانتظار موافقة أو تواصل البائع معك... ⏳', textAlign: TextAlign.right, style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}

// ==========================================
// 4. البوابة الأمنية (لوحة تحكم الإدارة الديناميكية الذكية)
// ==========================================

class AdminMarketDashboard extends StatefulWidget {
  const AdminMarketDashboard({super.key});

  @override
  State<AdminMarketDashboard> createState() => _AdminMarketDashboardState();
}

class _AdminMarketDashboardState extends State<AdminMarketDashboard> {
  int savedPendingCount = 0;
  int savedApprovedCount = 0;
  int savedSoldCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedCounts();
  }

  void _loadSavedCounts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedPendingCount = prefs.getInt('admin_pending_count') ?? 0;
      savedApprovedCount = prefs.getInt('admin_approved_count') ?? 0;
      savedSoldCount = prefs.getInt('admin_sold_count') ?? 0;
    });
  }

  void _updateSavedCount(String key, int newCount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, newCount);
    _loadSavedCounts(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(title: const Text('إدارة السوق القانوني', style: TextStyle(color: Colors.amber)), backgroundColor: AppColors.primary),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('book_market').snapshots(),
        builder: (context, snapshot) {
          int currentPending = 0;
          int currentApproved = 0;
          int currentSold = 0;

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final status = doc['status'];
              if (status == 'pending') currentPending++;
              if (status == 'approved') currentApproved++;
              if (status == 'sold') currentSold++;
            }
          }

          int newPending = (currentPending - savedPendingCount) > 0 ? (currentPending - savedPendingCount) : 0;
          int newApproved = (currentApproved - savedApprovedCount) > 0 ? (currentApproved - savedApprovedCount) : 0;
          int newSold = (currentSold - savedSoldCount) > 0 ? (currentSold - savedSoldCount) : 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildAdminCard(context, 'إدارة المواد الدراسية', 0, Icons.library_books, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManageStagesScreen()))),
              _buildAdminCard(context, 'الكتب قيد المراجعة', newPending, Icons.pending_actions, () {
                _updateSavedCount('admin_pending_count', currentPending);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReviewBooksScreen(status: 'pending')));
              }),
              _buildAdminCard(context, 'الكتب المقبولة (في السوق)', newApproved, Icons.check_circle, () {
                _updateSavedCount('admin_approved_count', currentApproved);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReviewBooksScreen(status: 'approved')));
              }),
              _buildAdminCard(context, 'سجل الكتب المباعة', newSold, Icons.monetization_on, () {
                _updateSavedCount('admin_sold_count', currentSold);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReviewBooksScreen(status: 'sold')));
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, String title, int newItemsCount, IconData icon, VoidCallback onTap) {
    return Card(
      color: const Color(0xFF1E2235),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Icon(icon, color: Colors.amber, size: 30),
        title: Text(title, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        trailing: newItemsCount > 0
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text('$newItemsCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            : const Icon(Icons.arrow_back_ios, size: 16, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}

class AdminManageStagesScreen extends StatelessWidget {
  const AdminManageStagesScreen({super.key});
  final stages = const ['المرحلة الأولى', 'المرحلة الثانية', 'المرحلة الثالثة', 'المرحلة الرابعة'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(title: const Text('إدارة مواد المراحل', style: TextStyle(color: Colors.amber)), backgroundColor: AppColors.primary),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: stages.length,
        itemBuilder: (context, index) => Card(
          color: const Color(0xFF1E2235),
          child: ListTile(
            title: Text(stages[index], textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            trailing: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.white54),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminManageSubjectsScreen(stageIndex: index + 1, stageName: stages[index]))),
          ),
        ),
      ),
    );
  }
}

class AdminManageSubjectsScreen extends StatelessWidget {
  final int stageIndex;
  final String stageName;
  const AdminManageSubjectsScreen({super.key, required this.stageIndex, required this.stageName});

  void _addSubject(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text('إضافة مادة للسوق', textAlign: TextAlign.right, style: TextStyle(color: Colors.amber)),
        content: TextField(controller: controller, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'اسم المادة', hintStyle: TextStyle(color: Colors.white54)), textAlign: TextAlign.right),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('market_settings').doc('stage_$stageIndex').collection('subjects').add({'name': controller.text.trim()});
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(title: Text('مواد $stageName'), backgroundColor: AppColors.primary),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber,
        onPressed: () => _addSubject(context), 
        icon: const Icon(Icons.add, color: AppColors.primary),
        label: const Text('إضافة مادة', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('market_settings').doc('stage_$stageIndex').collection('subjects').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('لا توجد مواد مضافة', style: TextStyle(color: Colors.white54)));
          
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) => Card(
              color: const Color(0xFF1E2235),
              child: ListTile(
                title: Text(docs[index]['name'], textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => FirebaseFirestore.instance.collection('market_settings').doc('stage_$stageIndex').collection('subjects').doc(docs[index].id).delete(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AdminReviewBooksScreen extends StatelessWidget {
  final String status;
  const AdminReviewBooksScreen({super.key, required this.status});

  void _changeStatus(BuildContext context, Map<String, dynamic> data, String id, String newStatus) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: Color(0xFF1E2235),
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.amber),
            SizedBox(width: 20),
            Text('جاري التنفيذ...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
    
    await FirebaseFirestore.instance.collection('book_market').doc(id).update({'status': newStatus});
    
    String sellerUid = data['sellerUid'];
    String bookTitle = data['title'];
    if (newStatus == 'approved') {
      await sendInAppNotification(sellerUid, 'تمت الموافقة! 🎉', 'وافقت الإدارة على عرض كتابك: $bookTitle');
    } else if (newStatus == 'rejected') {
      await sendInAppNotification(sellerUid, 'نعتذر، تم الرفض ❌', 'لم تتم الموافقة على عرض كتابك: $bookTitle');
    }

    if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // إغلاق التحميل بأمان
  }

  @override
  Widget build(BuildContext context) {
    String title = status == 'pending' ? 'طلبات قيد المراجعة' : (status == 'approved' ? 'الكتب المعروضة' : 'الكتب المباعة');
    
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(title: Text(title, style: const TextStyle(color: Colors.amber)), backgroundColor: AppColors.primary),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('book_market').where('status', isEqualTo: status).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
          
          final books = snapshot.data!.docs.toList();
          books.sort((a, b) {
            Timestamp t1 = a['createdAt'] as Timestamp? ?? Timestamp.now();
            Timestamp t2 = b['createdAt'] as Timestamp? ?? Timestamp.now();
            return t2.compareTo(t1); 
          });

          if (books.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_rounded, size: 80, color: Colors.white24),
                  SizedBox(height: 10),
                  Text('القائمة فارغة، لا توجد بيانات.', style: TextStyle(fontSize: 16, color: Colors.white54)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final data = books[index].data() as Map<String, dynamic>;
              final id = books[index].id;
              final imageUrl = data['imageUrl'] ?? 'default';
              
              return Card(
                color: Colors.white,
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      _buildBookCover(
                        imageUrl,
                        width: 80,
                        height: 110,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('الكتاب: ${data['title']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                            Text('المرحلة: ${data['stageName']} | المادة: ${data['subjectName']}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            Text('السعر: ${data['isFree'] == true ? 'مجاني' : data['price']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            Text('واتس: ${data['whatsapp']} | تليجرام: ${data['telegram']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            if (status == 'pending') ...[
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () => _changeStatus(context, data, id, 'rejected'),
                                    child: const Text('رفض', style: TextStyle(color: Colors.white)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    onPressed: () => _changeStatus(context, data, id, 'approved'),
                                    child: const Text('قبول ونشر', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ],
                            if (status == 'approved') ...[
                              const Divider(),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => _changeStatus(context, data, id, 'rejected'),
                                child: const Text('إزالة من السوق', style: TextStyle(color: Colors.white)),
                              )
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
 
