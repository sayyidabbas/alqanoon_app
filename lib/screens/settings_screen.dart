import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';

class SettingsScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? blockedUsers;
  final Function(int index)? onUnblockUser;

  const SettingsScreen({
    super.key,
    this.blockedUsers,
    this.onUnblockUser,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDeleting = false;

  // دالة إلغاء الحظر المباشر من Firestore
  Future<void> _unblockUserFromFirestore(String blockedUid, String userName) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .collection('blockedUsers')
          .doc(blockedUid)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إلغاء حظر $userName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إلغاء الحظر: $e')),
        );
      }
    }
  }

  // دالة حذف الحساب نهائياً مع التأكيد
  Future<void> _confirmAndDeleteAccount() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('تأكيد حذف الحساب', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف الحساب نهائياً؟\nسيتم حذف جميع بياناتك الشخصية ولا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isDeleting = true);

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                  await user.delete();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حذف الحساب بنجاح'), backgroundColor: Colors.orange),
                    );
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                  }
                }
              } on FirebaseAuthException catch (e) {
                if (mounted) {
                  setState(() => _isDeleting = false);
                  if (e.code == 'requires-recent-login') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لأسباب أمنية، يرجى إعادة تسجيل الدخول ثم محاولة حذف الحساب مجدداً.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ: ${e.message}'), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isDeleting = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حدث خطأ أثناء الحذف: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('نعم، احذف حسابي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // شاشة عرض المحظورين المباشرة من Firestore
  void _openBlockedListModal() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('قائمة المحظورين 🚫', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.accent)),
            const Divider(color: Colors.white10, height: 24),
            Expanded(
              child: currentUid == null
                  ? const Center(child: Text('يرجى تسجيل الدخول أولاً', style: TextStyle(color: Colors.white54)))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUid)
                          .collection('blockedUsers')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                        }
                        if (snapshot.hasError) {
                          return const Center(child: Text('حدث خطأ أثناء جلب القائمة', style: TextStyle(color: Colors.redAccent)));
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Center(child: Text('لا يوجد مستخدمون محظورون', style: TextStyle(color: Colors.white54)));
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final String blockedUid = docs[index].id;
                            final String fullName = data['fullName'] ?? 'مستخدم';
                            final String username = data['username'] ?? 'user';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.accent,
                                child: Text(
                                  fullName.isNotEmpty ? fullName[0] : 'ع',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text('@$username', style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                              trailing: TextButton(
                                onPressed: () => _unblockUserFromFirestore(blockedUid, fullName),
                                child: const Text('إلغاء الحظر', style: TextStyle(color: AppColors.accent)),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: _isDeleting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.redAccent),
                  SizedBox(height: 16),
                  Text('جاري حذف الحساب والبيانات...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.block, color: Colors.orangeAccent),
                        title: const Text('قائمة المحظورين', style: TextStyle(color: Colors.white)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (currentUid != null)
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUid)
                                    .collection('blockedUsers')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  final count = snapshot.data?.docs.length ?? 0;
                                  return Text('$count', style: const TextStyle(color: Colors.white54, fontSize: 13));
                                },
                              )
                            else
                              const Text('0', style: TextStyle(color: Colors.white54, fontSize: 13)),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                          ],
                        ),
                        onTap: _openBlockedListModal,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                    title: const Text('حذف الحساب نهائياً', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    subtitle: const Text('سيتم حذف كافة البيانات والأنشطة الخاصة بك', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    onTap: _confirmAndDeleteAccount,
                  ),
                ),
              ],
            ),
    );
  }
}
