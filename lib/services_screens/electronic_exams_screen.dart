import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:http/http.dart' as http; 
import 'package:googleapis_auth/auth_io.dart' as auth; 
import '../constants/app_colors.dart';

// ==========================================
// دوال مساعدة عامة
// ==========================================

Future<void> sendInAppNotification(String userId, String title, String body, {String? type}) async {
  if (userId.isEmpty) return;
  
  await FirebaseFirestore.instance.collection('market_notifications').add({
    'userId': userId,
    'title': title,
    'body': body,
    'type': type ?? '',
    'isRead': false,
    'createdAt': FieldValue.serverTimestamp(),
  });

  try {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data() != null) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? fcmToken = userData['fcmToken'];

      if (fcmToken != null && fcmToken.isNotEmpty) {
        final serviceAccountJson = {
          "type": "service_account",
          "project_id": "law-platform-55632",
          "private_key_id": "4612406d8276f74f5bb5821ab1dce282476021df",
          "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC/ptuvFSaxEjpW\nLkrmvglfZwRk8NPM+fi8Mc4TXNzw5imzkqtmX/4JHMeWCbtYvlo+rL0nE21oNpEP\n/3gI8hgsLzie0Yivm3+0dhZ0xN/H93e+XGUmZgyMf1TZnz0kYkSw+FbPijojKTNz\nbodO6PovSpVUFOYbV5gnEcNyutUwS/kve2nUw2QEG8RsZmEaRuKhcwUT5oL8n32Q\noiVn6xcHwjr9LeqUL878i8XYXYW2HIRMs0WyPpwbATg6QJQlMf47R9A0DMGXwVw/\naNcvvuOQ/RN62+qTA+6nVcpNRQW4BrWR/pRGzeWz0z9kW0XoeDJyKC5eXcep0Ptx\nKdDgsA+tAgMBAAECggEAEJ80Jnc7J9hg3uCc9m48+d1BcE/CzuBPRmM7cEp5jxsn\nOr/ZxcNFkRzB4q1tZkD8KrtonF7++i7hXfXWP1Bf8FUYIA4kQLbH2Kr1P6NjlUBN\nTmFNFIt9QyI4Bbfd4a30LzUasl1WtX35TGWlrp5eNIPPd79oRa7PL3RG80ho/Qsz\nXYIoRBfoKWdoKbN+XxHMVl2dMccnP1dTOa9jR6hhvSRZSKrwAz5Ia5lyVAKrahIv\nxZDX6nCvn3N7aqcjTV7qQ2YFi0I0hkzPBrEJxTSkGWcIzN1fDCmsm7irlBHkeVAt\ntyWNTefROq47ApfzzfIjctrtdibkyIMC+ExFpPoyMQKBgQDj3Jlv4vyLiIwQ8jHE\nwSK14htAUkGNmTsAvW9eyeiaTGdc/ltndKt7SGvDaS38J6+LYqBcLrAsmdu592b9\ngH5EypL9+N3uT42SJMGR4M5cH5ZqyvdZ4NTCDMjSq3h77ROLJ2Oha6Q1na1XyXZe\ntMzZ19k0C4GxjcjJeGYX3NG9VwKBgQDXUY2VfzDD4s85pI6vVET9W/1ZxZeUtoIY\n+UYCSpz/RoVGQl7SeSFv5zR12RJgztlXr9stdusfVFQGLo68c/XbkMLUshitEQPO\n/aVEqrW9ZbrfR04j0DzUzjKPpjyR733tvBF4YBELrD3KBcXO+cCKpBwo72Xz6Cgb\nH4gvI/F0mwKBgFszdXpx+LEEk0NJHSBqSTFRcaTaB4DcXuBZ8hSXbfEsOYbgC8ep\ny+UJRJCvLYeqfrmkXRjoWv1PC8IwQtmeL2vrRNBAZtu2naxr58oyl4YJ4pOV71Db\nC20r3slrdkrrxhHBT0BRrCUFmlbzvNwFM6TRnw8Ut/FQFZiGBx7v9Eb7AoGAS+/G\nGChAQYVXAgRIEguNPTFZG3T1LYxkO3yGNT6tOdZcIFg96sqvgTCwLrO8qImq2yL5\nEIK1D1qFO5zl2A6pcaMPI0YgL8Elb7XCuIHgEIi1LBOQuk6xdXe3GzRMfkdRSSuf\nma1/tXcsX3hDt+gbAIo6KDGt6iRBKLepJr7tY+sCgYEAtz1LNY2nlE5R+LeunVL6\nXUhI8pXkxzpKeuspYTTrbR2Ca1V7XgRoY+V8rD7WbUFA7KiBLIff4TntAVqPZzVS\nU18LFSMJuju2yfXxmF0IbNMEzaUaeoM/88dfawxnOMfgpzOSDXRvPv7b6QoACfNG\nQPDdJPQJHaE6Bt+o8FTWrt4=\n-----END PRIVATE KEY-----\n",
          "client_email": "firebase-adminsdk-fbsvc@law-platform-55632.iam.gserviceaccount.com",
          "client_id": "111366556927016010526",
          "auth_uri": "https://accounts.google.com/o/oauth2/auth",
          "token_uri": "https://oauth2.googleapis.com/token",
          "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
          "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40law-platform-55632.iam.gserviceaccount.com",
          "universe_domain": "googleapis.com"
        };

        List<String> scopes = ["https://www.googleapis.com/auth/firebase.messaging"];
        
        auth.AuthClient client = await auth.clientViaServiceAccount(
          auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
          scopes,
        );

        final String projectId = serviceAccountJson['project_id']!;
        final String endpoint = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

        final response = await client.post(
          Uri.parse(endpoint),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonEncode(
            <String, dynamic>{
              'message': <String, dynamic>{
                'token': fcmToken,
                'notification': <String, dynamic>{
                  'title': title,
                  'body': body,
                },
                'android': <String, dynamic>{
                  'priority': 'high',
                  'notification': <String, dynamic>{
                    'sound': 'default',
                  },
                },
                'apns': <String, dynamic>{
                  'payload': <String, dynamic>{
                    'aps': <String, dynamic>{
                      'sound': 'default',
                    },
                  },
                },
                'data': <String, dynamic>{
                  'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  'type': type ?? '',
                },
              },
            },
          ),
        );
        
        if (response.statusCode == 200) {
          debugPrint('تم إرسال الإشعار الخارجي بنجاح (V1)');
        } else {
          debugPrint('حدث خطأ أثناء إرسال الإشعار من سيرفر جوجل: ${response.body}');
        }
        
        client.close();
      }
    }
  } catch (e) {
    debugPrint('خطأ برمجي في إرسال الإشعار الخارجي: $e');
  }
}

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

Future<void> _launchContactUrl(BuildContext context, String type, String contactInfo) async {
  String url = '';
  if (type == 'whatsapp') {
    String cleanPhone = contactInfo.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '964${cleanPhone.substring(1)}';
    }
    url = 'https://wa.me/$cleanPhone';
  } else if (type == 'telegram') {
    String cleanTg = contactInfo.replaceAll('@', '').trim();
    url = 'https://t.me/$cleanTg';
  }

  final Uri uri = Uri.parse(url);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح التطبيق، تأكد من تثبيته على هاتفك.')),
      );
    }
  }
}

// ==========================================
// الشاشة الرئيسية للسوق القانوني
// ==========================================

class BookMarketScreen extends StatefulWidget {
  const BookMarketScreen({super.key});

  @override
  State<BookMarketScreen> createState() => _BookMarketScreenState();
}

class _BookMarketScreenState extends State<BookMarketScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('سوق الكتب القانونية', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_rounded, color: Colors.white),
            tooltip: 'مشترياتي ومبيعاتي',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserMarketProfileScreen())),
          ),
          // تمت إزالة زر البوابة الآمنة من هنا
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
                'سوق الكتب القانونية',
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

    final nav = Navigator.of(context, rootNavigator: true);
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
      
      nav.pop();

      if (mounted) {
        Navigator.pop(context); 
        Navigator.pop(context); 
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
      nav.pop(); 
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
                      final navRoot = Navigator.of(context, rootNavigator: true);
                      final navContext = Navigator.of(ctx);

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

                      try {
                        await sendInAppNotification(bookData['sellerUid'], 'طلب شراء جديد! 🎉', 'يرغب ${nameController.text.trim()} بشراء كتابك: ${bookData['title']}', type: 'new_purchase_request');

                        await FirebaseFirestore.instance.collection('book_market').doc(bookId).update({
                          'status': 'reserved',
                          'buyerUid': uid,
                          'buyerName': nameController.text.trim(),
                          'buyerContact': contactController.text.trim(),
                        });

                        navRoot.pop(); 
                        navContext.pop(); 
                        
                        if (context.mounted) {
                          Navigator.pop(context); 
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الإرسال! سيصل للبائع إشعار وسيتم التواصل معك قريباً.')));
                        }
                      } catch (e) {
                        navRoot.pop(); 
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
                        }
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

class UserMarketProfileScreen extends StatefulWidget {
  const UserMarketProfileScreen({super.key});

  @override
  State<UserMarketProfileScreen> createState() => _UserMarketProfileScreenState();
}

class _UserMarketProfileScreenState extends State<UserMarketProfileScreen> {
  int storedBuyerCount = 0;
  int storedSellerCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStoredCounts();
  }

  Future<void> _loadStoredCounts() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        storedBuyerCount = prefs.getInt('buyer_seen_cnt') ?? 0;
        storedSellerCount = prefs.getInt('seller_seen_cnt') ?? 0;
      });
    }
  }

  Future<void> _updateStoredCount(String key, int count) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(key) ?? 0;
    if (current != count) {
      await prefs.setInt(key, count);
      _loadStoredCounts(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          title: const Text('ملفي في السوق'),
          backgroundColor: AppColors.primary,
          bottom: TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('book_market').where('buyerUid', isEqualTo: uid).where('status', isEqualTo: 'sold').snapshots(),
                  builder: (context, snapshot) {
                    int currentCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    int badgeCount = currentCount - storedBuyerCount;
                    if (badgeCount < 0) badgeCount = 0;

                    return Badge(
                      isLabelVisible: badgeCount > 0,
                      label: Text('$badgeCount'),
                      backgroundColor: Colors.red,
                      child: const Text('طلبات الشراء', overflow: TextOverflow.ellipsis),
                    );
                  }
                ),
              ),
              Tab(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('book_market').where('sellerUid', isEqualTo: uid).where('status', isEqualTo: 'reserved').snapshots(),
                  builder: (context, snapshot) {
                    int currentCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    int badgeCount = currentCount - storedSellerCount;
                    if (badgeCount < 0) badgeCount = 0;

                    return Badge(
                      isLabelVisible: badgeCount > 0,
                      label: Text('$badgeCount'),
                      backgroundColor: Colors.red,
                      child: const Text('كتبي المعروضة', overflow: TextOverflow.ellipsis),
                    );
                  }
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            BuyerRequestsTab(onViewed: (count) => _updateStoredCount('buyer_seen_cnt', count)),
            SellerBooksTab(onViewed: (count) => _updateStoredCount('seller_seen_cnt', count)),
          ],
        ),
      ),
    );
  }
}

class SellerBooksTab extends StatelessWidget {
  final Function(int) onViewed;
  const SellerBooksTab({super.key, required this.onViewed});

  void _acceptRequest(BuildContext context, String bookId, String buyerUid, String bookTitle) async {
    final nav = Navigator.of(context, rootNavigator: true);
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
    
    try {
      await FirebaseFirestore.instance.collection('book_market').doc(bookId).update({'status': 'sold'});
      await sendInAppNotification(buyerUid, 'تم تأكيد البيع 🤝', 'وافق البائع على تسليمك كتاب: $bookTitle', type: 'seller_approved');
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      nav.pop(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('book_market').where('sellerUid', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        
        final books = snapshot.data!.docs.toList();
        
        int actionableCount = books.where((b) => (b.data() as Map<String, dynamic>)['status'] == 'reserved').length;
        WidgetsBinding.instance.addPostFrameCallback((_) => onViewed(actionableCount));

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
  final Function(int) onViewed;
  const BuyerRequestsTab({super.key, required this.onViewed});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('book_market').where('buyerUid', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        
        final books = snapshot.data!.docs.toList();
        
        int actionableCount = books.where((b) => (b.data() as Map<String, dynamic>)['status'] == 'sold').length;
        WidgetsBinding.instance.addPostFrameCallback((_) => onViewed(actionableCount));

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

// لوحة التحكم (سيتم فتحها من المركزية)
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
    final nav = Navigator.of(context, rootNavigator: true);
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
    
    try {
      await FirebaseFirestore.instance.collection('book_market').doc(id).update({'status': newStatus});
      
      String sellerUid = data['sellerUid'];
      String bookTitle = data['title'];
      if (newStatus == 'approved') {
        await sendInAppNotification(sellerUid, 'تمت الموافقة! 🎉', 'وافقت الإدارة على عرض كتابك: $bookTitle', type: 'admin_approved_book');
      } else if (newStatus == 'rejected') {
        await sendInAppNotification(sellerUid, 'نعتذر، تم الرفض ❌', 'لم تتم الموافقة على عرض كتابك: $bookTitle');
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      nav.pop();
    }
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
