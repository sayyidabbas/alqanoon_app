import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // مكتبة المصادقة لفحص الجلسة
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // حركات مطرقة القاضي (ضربة قوية)
  late Animation<double> _gavelScale;
  late Animation<double> _gavelRotation;
  
  // موجة الاصطدام والشرارات
  late Animation<double> _shockwave;
  
  // ظهور النصوص
  late Animation<double> _titleScale;
  late Animation<double> _titleOpacity;
  
  // ظهور اسم المطور (سيدعباس)
  late Animation<double> _nameOpacity;
  late Animation<Offset> _nameSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000), 
    );

    // 1. المطرقة تهوي بقوة (من البداية إلى 30%)
    _gavelScale = Tween<double>(begin: 4.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeInExpo)),
    );
    _gavelRotation = Tween<double>(begin: -pi / 4, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeInExpo)),
    );

    // 2. الانفجار وموجة الصدمة عند الضربة (من 30% إلى 60%)
    _shockwave = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.7, curve: Curves.easeOut)),
    );

    // 3. انبثاق اسم المنصة بارتداد قوي (من 35% إلى 70%)
    _titleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.35, 0.7, curve: Curves.elasticOut)),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.35, 0.5, curve: Curves.easeIn)),
    );

    // 4. ظهور اسم "سيدعباس عقيل الحسيني" بانزلاق أنيق (من 65% إلى 90%)
    _nameOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.65, 0.9, curve: Curves.easeIn)),
    );
    _nameSlide = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.65, 0.9, curve: Curves.easeOutCubic)),
    );

    _controller.forward();

    // 🚀 التوجيه الذكي بعد انتهاء الأنيميشن وفحص تسجيل الدخول
    Timer(const Duration(milliseconds: 5000), () {
      if (mounted) {
        if (FirebaseAuth.instance.currentUser != null) {
          // المستخدم مسجل دخوله بالفعل -> اذهب للرئيسية مباشرة
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          // لا يوجد مستخدم -> اذهب لصفحة تسجيل الدخول
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07080B), 
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              if (_controller.value >= 0.3)
                CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: ShockwavePainter(progress: _shockwave.value),
                ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: _gavelScale.value,
                    child: Transform.rotate(
                      angle: _gavelRotation.value,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: _controller.value >= 0.3 
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.4 * (1 - _shockwave.value)),
                                  blurRadius: 50,
                                  spreadRadius: 10,
                                )
                              ] 
                            : [],
                        ),
                        child: Icon(
                          Icons.gavel_rounded,
                          size: 60,
                          color: _controller.value < 0.3 
                              ? Colors.white.withOpacity(0.5) 
                              : const Color(0xFFFFD700), 
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Opacity(
                    opacity: _titleOpacity.value,
                    child: Transform.scale(
                      scale: _titleScale.value,
                      child: Column(
                        children: [
                          const Text(
                            'مـنـصّـة الـقـانـون',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.0,
                              shadows: [
                                Shadow(
                                  color: Color(0xFFFFD700),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          
                          Opacity(
                            opacity: _shockwave.value,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80 * _shockwave.value,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.transparent, const Color(0xFFFFD700).withOpacity(0.8)],
                                    )
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Icon(Icons.balance, size: 20, color: Color(0xFFFFD700)),
                                ),
                                Container(
                                  width: 80 * _shockwave.value,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [const Color(0xFFFFD700).withOpacity(0.8), Colors.transparent],
                                    )
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  SlideTransition(
                    position: _nameSlide,
                    child: Opacity(
                      opacity: _nameOpacity.value,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFDF00),
                            Color(0xFFD4AF37),
                            Color(0xFF996515),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'سيدعباس عقيل الحسيني',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class ShockwavePainter extends CustomPainter {
  final double progress;

  ShockwavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = Offset(size.width / 2, size.height / 2.5); 
    
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * (1 - progress) 
      ..color = const Color(0xFFFFD700).withOpacity((1 - progress).clamp(0.0, 1.0));

    canvas.drawCircle(center, progress * size.width * 0.8, ringPaint);

    final sparkPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    final random = Random(123); 
    int sparkCount = 24;

    for (int i = 0; i < sparkCount; i++) {
      double angle = (i * 2 * pi / sparkCount) + (random.nextDouble() * 0.2);
      
      double distance = progress * size.width * (0.4 + random.nextDouble() * 0.4);
      double length = 20 * (1 - progress); 

      Offset start = center + Offset(cos(angle) * distance, sin(angle) * distance);
      Offset end = center + Offset(cos(angle) * (distance + length), sin(angle) * (distance + length));

      sparkPaint.color = const Color(0xFFFFD700).withOpacity((1 - progress).clamp(0.0, 1.0));
      canvas.drawLine(start, end, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ShockwavePainter oldDelegate) => true;
}
 
