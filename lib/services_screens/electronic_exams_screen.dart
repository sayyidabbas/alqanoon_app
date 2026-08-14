import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';

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
        title: const Text('البوابة الآمنة - الإدارة', textAlign: TextAlign.right),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(hintText: 'أدخل كلمة السر'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
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
            child: const Text('دخول'),
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
        title: const Text('مكتبة الحقوق التفاعلية', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: 'مشترياتي ومبيعاتي',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserMarketProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
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
              const Icon(Icons.account_balance, size: 80, color: Colors.amber),
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
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
// اختيار المرحلة الدراسية (للإضافة أو التصفح)
// ==========================================

class SelectStageScreen extends StatelessWidget {
  final bool isAddingBook;
  const SelectStageScreen({super.key, required this.isAddingBook});

  final List<String> stages = const ['المرحلة الأولى', 'المرحلة الثانية', 'المرحلة الثالثة', 'المرحلة الرابعة'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAddingBook ? 'اختر مرحلة الكتاب' : 'تصفح حسب المرحلة'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stages.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Colors.amber.shade100,
                child: Text('${index + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              title: Text(stages[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.right),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
// 1. مسار البائع (إضافة كتاب + رفع صورة أونلاين)
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
  bool _isLoading = false;
  File? _imageFile; // لتخزين الصورة محلياً قبل الرفع

  // دالة اختيار الصورة من المعرض
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
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

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_uid';
      String imageUrl = 'default';

      // رفع الصورة أونلاين إلى Firebase Storage إذا قام الطالب باختيارها
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance.ref().child('book_covers/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(_imageFile!);
        imageUrl = await storageRef.getDownloadURL();
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
        'status': 'pending', // يذهب للمراجعة أولاً
        'imageUrl': imageUrl, // تم ربط رابط الصورة المرفوعة
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); // العودة
        Navigator.pop(context); // العودة للرئيسية
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('تم الإرسال بنجاح', textAlign: TextAlign.right),
            content: const Text('تم إرسال كتابك للإدارة للمراجعة. سيظهر في السوق فور الموافقة عليه.', textAlign: TextAlign.right),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('عرض كتاب - ${widget.stageName}'), backgroundColor: AppColors.primary),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // تصميم زر رفع الصورة
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 160,
                      width: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.amber, width: 2, style: BorderStyle.solid),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Image.file(_imageFile!, fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: AppColors.primary, size: 40),
                                SizedBox(height: 8),
                                Text('أضف الغلاف', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                const Text('المعلومات الأساسية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary), textAlign: TextAlign.right),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _titleController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'اسم الكتاب', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _authorController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'اسم المؤلف', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 15),
                
                // جلب المواد من الإدارة
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('market_settings').doc('stage_${widget.stageIndex}').collection('subjects').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    final subjects = snapshot.data!.docs.map((e) => e['name'] as String).toList();
                    if (subjects.isEmpty) return const Text('لا توجد مواد مضافة لهذه المرحلة من قبل الإدارة', style: TextStyle(color: Colors.red));
                    
                    return DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      decoration: const InputDecoration(labelText: 'اختر المادة الدراسية', border: OutlineInputBorder()),
                      items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, textAlign: TextAlign.right))).toList(),
                      onChanged: (v) => setState(() => _selectedSubject = v),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                const Text('نوع العرض', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary), textAlign: TextAlign.right),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('بمبلغ مالي', textAlign: TextAlign.right),
                        value: false,
                        groupValue: _isFree,
                        onChanged: (v) => setState(() => _isFree = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('مجاني (خيري)', textAlign: TextAlign.right),
                        value: true,
                        groupValue: _isFree,
                        onChanged: (v) => setState(() => _isFree = v!),
                      ),
                    ),
                  ],
                ),
                if (!_isFree) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(labelText: 'السعر (بالدينار العراقي)', border: OutlineInputBorder(), prefixText: 'د.ع '),
                    validator: (v) => v!.isEmpty ? 'يرجى إدخال السعر' : null,
                  ),
                ],

                const SizedBox(height: 20),
                const Text('معلومات التواصل (أدخل واحدة على الأقل)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary), textAlign: TextAlign.right),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'رقم الواتساب', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone, color: Colors.green)),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _telegramController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'معرف التليجرام (بدون @)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.send, color: Colors.blue)),
                ),

                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(vertical: 16)),
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
// 2. مسار المشتري (تصفح الكتب)
// ==========================================

class BrowseSubjectsScreen extends StatelessWidget {
  final int stageIndex;
  final String stageName;
  const BrowseSubjectsScreen({super.key, required this.stageIndex, required this.stageName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('مواد $stageName'), backgroundColor: AppColors.primary),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('market_settings').doc('stage_$stageIndex').collection('subjects').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('لا توجد مواد مضافة'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final subjectName = docs[index]['name'];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(subjectName, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
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
      appBar: AppBar(title: Text('كتب $subjectName'), backgroundColor: AppColors.primary),
      body: StreamBuilder<QuerySnapshot>(
        // تم حل مشكلة Index (الشاشة السوداء) بإزالة orderBy وترتيبها محلياً في الأسفل
        stream: FirebaseFirestore.instance
            .collection('book_market')
            .where('stageIndex', isEqualTo: stageIndex)
            .where('subjectName', isEqualTo: subjectName)
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('حدث خطأ في جلب البيانات', style: const TextStyle(color: Colors.white)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          // جلب الكتب وترتيبها محلياً من الأحدث للأقدم لتجنب خطأ الـ Index
          final books = snapshot.data!.docs.toList();
          books.sort((a, b) {
            Timestamp t1 = a['createdAt'] as Timestamp? ?? Timestamp.now();
            Timestamp t2 = b['createdAt'] as Timestamp? ?? Timestamp.now();
            return t2.compareTo(t1); 
          });

          if (books.isEmpty) return const Center(child: Text('لا توجد كتب معروضة لهذه المادة حالياً', style: TextStyle(fontSize: 16, color: Colors.white70)));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final data = books[index].data() as Map<String, dynamic>;
              final bookId = books[index].id;
              final isFree = data['isFree'] ?? false;
              final imageUrl = data['imageUrl'] ?? 'default';

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.only(bottom: 15),
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailsScreen(bookId: bookId, bookData: data))),
                  child: Row(
                    children: [
                      Container(
                        width: 100,
                        height: 130,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
                        ),
                        // عرض الصورة المرفوعة أونلاين
                        child: imageUrl != 'default'
                            ? ClipRRect(
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  errorWidget: (context, url, error) => const Icon(Icons.book, size: 50, color: Colors.grey),
                                ),
                              )
                            : Container(color: Colors.grey.shade200, child: const Icon(Icons.book, size: 50, color: Colors.grey)),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
                              const SizedBox(height: 5),
                              Text('المؤلف: ${data['author']}', style: const TextStyle(color: Colors.grey), textAlign: TextAlign.right),
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

  void _requestBook(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    if (uid == bookData['sellerUid']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكنك طلب كتابك الخاص!')));
      return;
    }

    // تغيير حالة الكتاب إلى محجوز (Reserved)
    await FirebaseFirestore.instance.collection('book_market').doc(bookId).update({
      'status': 'reserved',
      'buyerUid': uid,
    });

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب الشراء للبائع. تابعه من ملفك الشخصي.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFree = bookData['isFree'] ?? false;
    final imageUrl = bookData['imageUrl'] ?? 'default';

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الكتاب'), backgroundColor: AppColors.primary),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(
              child: Container(
                height: 220,
                width: 160,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                child: imageUrl != 'default'
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.book, size: 80, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.book, size: 80, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            Text(bookData['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary), textAlign: TextAlign.right),
            const SizedBox(height: 10),
            Text('المؤلف: ${bookData['author']}', style: const TextStyle(fontSize: 18, color: Colors.grey), textAlign: TextAlign.right),
            const Divider(height: 30, thickness: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isFree ? 'مجاني' : '${bookData['price']} د.ع', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isFree ? Colors.green : Colors.orange)),
                const Text('السعر:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('المادة الدراسية:', style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.right),
            Text('${bookData['stageName']} - ${bookData['subjectName']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 15)),
                icon: const Icon(Icons.shopping_cart, color: Colors.amber),
                label: Text(isFree ? 'طلب الحصول على الكتاب مجاناً' : 'طلب شراء الكتاب', style: const TextStyle(fontSize: 18, color: Colors.amber)),
                onPressed: () => _requestBook(context),
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
        appBar: AppBar(
          title: const Text('ملفي في السوق'),
          backgroundColor: AppColors.primary,
          bottom: const TabBar(
            indicatorColor: Colors.amber,
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

  void _acceptRequest(String bookId) async {
    await FirebaseFirestore.instance.collection('book_market').doc(bookId).update({'status': 'sold'});
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      // تم إزالة orderBy لعدم طلب فهرسة (Index)
      stream: FirebaseFirestore.instance.collection('book_market').where('sellerUid', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        // ترتيب البيانات محلياً
        final books = snapshot.data!.docs.toList();
        books.sort((a, b) {
          Timestamp t1 = a['createdAt'] as Timestamp? ?? Timestamp.now();
          Timestamp t2 = b['createdAt'] as Timestamp? ?? Timestamp.now();
          return t2.compareTo(t1); 
        });

        if (books.isEmpty) return const Center(child: Text('لم تقم بعرض أي كتب.'));

        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final data = books[index].data() as Map<String, dynamic>;
            final status = data['status'];
            String statusText = '';
            Color statusColor = Colors.grey;

            if (status == 'pending') { statusText = 'قيد المراجعة'; statusColor = Colors.orange; }
            else if (status == 'approved') { statusText = 'معروض في السوق'; statusColor = Colors.blue; }
            else if (status == 'reserved') { statusText = 'مطلوب للشراء!'; statusColor = Colors.red; }
            else if (status == 'sold') { statusText = 'تم البيع'; statusColor = Colors.green; }
            else if (status == 'rejected') { statusText = 'مرفوض'; statusColor = Colors.black; }

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(data['title'] ?? ''),
                subtitle: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                trailing: status == 'reserved' 
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () => _acceptRequest(books[index].id),
                        child: const Text('تأكيد البيع'),
                      )
                    : null,
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

  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('book_market').where('buyerUid', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final books = snapshot.data!.docs.toList();
        books.sort((a, b) {
          Timestamp t1 = a['createdAt'] as Timestamp? ?? Timestamp.now();
          Timestamp t2 = b['createdAt'] as Timestamp? ?? Timestamp.now();
          return t2.compareTo(t1); 
        });

        if (books.isEmpty) return const Center(child: Text('ليس لديك طلبات شراء حالياً.'));

        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final data = books[index].data() as Map<String, dynamic>;
            final status = data['status'];
            
            if (status == 'sold') {
              return Card(
                color: Colors.green.shade50,
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('تمت الموافقة على شراء: ${data['title']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      const Text('تواصل مع البائع لإتمام الاستلام:', style: TextStyle(color: Colors.green)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if ((data['whatsapp'] ?? '').isNotEmpty)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              icon: const Icon(Icons.phone),
                              label: const Text('واتساب'),
                              onPressed: () => _launchURL('https://wa.me/${data['whatsapp']}'),
                            ),
                          if ((data['telegram'] ?? '').isNotEmpty)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              icon: const Icon(Icons.send),
                              label: const Text('تليجرام'),
                              onPressed: () => _launchURL('https://t.me/${data['telegram']}'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['title'] ?? ''),
                  subtitle: const Text('بانتظار موافقة البائع...', style: TextStyle(color: Colors.orange)),
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
// 4. البوابة الأمنية (لوحة تحكم الإدارة)
// ==========================================

class AdminMarketDashboard extends StatelessWidget {
  const AdminMarketDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة السوق القانوني'), backgroundColor: AppColors.primary),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAdminCard(context, 'إدارة المواد الدراسية', Icons.library_books, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManageStagesScreen()))),
          _buildAdminCard(context, 'الكتب قيد المراجعة', Icons.pending_actions, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReviewBooksScreen(status: 'pending')))),
          _buildAdminCard(context, 'الكتب المقبولة (في السوق)', Icons.check_circle, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReviewBooksScreen(status: 'approved')))),
          _buildAdminCard(context, 'سجل الكتب المباعة', Icons.monetization_on, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReviewBooksScreen(status: 'sold')))),
        ],
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_back_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// إدارة المواد (بسيطة مشابهة لبنك الأسئلة)
class AdminManageStagesScreen extends StatelessWidget {
  const AdminManageStagesScreen({super.key});
  final stages = const ['المرحلة الأولى', 'المرحلة الثانية', 'المرحلة الثالثة', 'المرحلة الرابعة'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة مواد المراحل'), backgroundColor: AppColors.primary),
      body: ListView.builder(
        itemCount: stages.length,
        itemBuilder: (context, index) => Card(
          child: ListTile(
            title: Text(stages[index], textAlign: TextAlign.right),
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
        title: const Text('إضافة مادة للسوق'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'اسم المادة')),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('market_settings').doc('stage_$stageIndex').collection('subjects').add({'name': controller.text.trim()});
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('مواد $stageName'), backgroundColor: AppColors.primary),
      floatingActionButton: FloatingActionButton(onPressed: () => _addSubject(context), child: const Icon(Icons.add)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('market_settings').doc('stage_$stageIndex').collection('subjects').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(docs[index]['name'], textAlign: TextAlign.right),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => FirebaseFirestore.instance.collection('market_settings').doc('stage_$stageIndex').collection('subjects').doc(docs[index].id).delete(),
              ),
            ),
          );
        },
      ),
    );
  }
}

// مراجعة وقبول الكتب
class AdminReviewBooksScreen extends StatelessWidget {
  final String status; // 'pending', 'approved', 'sold'
  const AdminReviewBooksScreen({super.key, required this.status});

  void _changeStatus(String id, String newStatus) async {
    await FirebaseFirestore.instance.collection('book_market').doc(id).update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    String title = status == 'pending' ? 'طلبات قيد المراجعة' : (status == 'approved' ? 'الكتب المعروضة' : 'الكتب المباعة');
    
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: AppColors.primary),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('book_market').where('status', isEqualTo: status).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final books = snapshot.data!.docs.toList();
          books.sort((a, b) {
            Timestamp t1 = a['createdAt'] as Timestamp? ?? Timestamp.now();
            Timestamp t2 = b['createdAt'] as Timestamp? ?? Timestamp.now();
            return t2.compareTo(t1); 
          });

          if (books.isEmpty) return const Center(child: Text('لا توجد بيانات.'));

          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final data = books[index].data() as Map<String, dynamic>;
              final id = books[index].id;
              final imageUrl = data['imageUrl'] ?? 'default';
              
              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 110,
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                        child: imageUrl != 'default'
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => const Icon(Icons.book, color: Colors.grey),
                                ),
                              )
                            : const Icon(Icons.book, size: 40, color: Colors.grey),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('الكتاب: ${data['title']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('المرحلة: ${data['stageName']} | المادة: ${data['subjectName']}'),
                            Text('السعر: ${data['isFree'] == true ? 'مجاني' : data['price']}'),
                            Text('واتس: ${data['whatsapp']} | تليجرام: ${data['telegram']}'),
                            if (status == 'pending') ...[
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () => _changeStatus(id, 'rejected'),
                                    child: const Text('رفض'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    onPressed: () => _changeStatus(id, 'approved'),
                                    child: const Text('قبول ونشر'),
                                  ),
                                ],
                              ),
                            ],
                            if (status == 'approved') ...[
                              const Divider(),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => _changeStatus(id, 'rejected'),
                                child: const Text('إزالة من السوق'),
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
 
