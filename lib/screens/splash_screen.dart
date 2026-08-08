import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // أنيميشن الدوران والتجمع اللولبي
  late Animation<double> _spiralAnimation;
  // أنيميشن تصادم وانبثاق النص
  late Animation<double> _impactAnimation;
  // أنيميشن التوهج النهائي
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // 1. مرحلة اقتراب العنصرين بشكل لولبي (من 0% إلى 60% من الوقت)
    _spiralAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.60, curve: Curves.easeInOutCubic),
    );

    // 2. مرحلة الاصطدام وظهور النص (من 55% إلى 85% من الوقت)
    _impactAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.85, curve: Curves.elasticOut),
    );

    // 3. التوهج واستقرار الاسم (من 80% إلى 100%)
    _glowAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.80, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();

    // الانتقال للـ Login بعد انتهاء العرض
    Timer(const Duration(milliseconds: 4200), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF090A0F), // خلفية ليلية فاخرة عميقة
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double spiralVal = _spiralAnimation.value;
          double impactVal = _impactAnimation.value;
          double glowVal = _glowAnimation.value;

          // حساب المسارات اللولبية للعنصرين
          // العنصر 1: ميزان العدالة ⚖️
          double angle1 = spiralVal * 4 * pi; // دوران 2 دورة كاملة
          double radius1 = (1 - spiralVal) * (size.width * 0.45);
          double x1 = cos(angle1) * radius1;
          double y1 = sin(angle1) * radius1;

          // العنصر 2: مطرقة القاضي 🔨 (في الاتجاه المعاكس)
          double angle2 = angle1 + pi; 
          double x2 = cos(angle2) * radius1;
          double y2 = sin(angle2) * radius1;

          return Stack(
            alignment: Alignment.center,
            children: [
              // 1. رسم الخطوط اللولبية الضوئية في الخلفية
              CustomPaint(
                size: Size(size.width, size.height),
                painter: SpiralGlowPainter(progress: spiralVal, impactProgress: impactVal),
              ),

              // 2. الهالة الضوئية المركزية لحظة الاصطدام
              if (spiralVal > 0.4)
                Transform.scale(
                  scale: impactVal * 1.8,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.accent.withOpacity(0.8 * (1 - glowVal * 0.3)),
                          const Color(0xFFFFD700).withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // 3. العنصر القانوني الأول: الميزان ⚖️ (يدور ويتلاشى عند الاصطدام)
              if (spiralVal < 0.65)
                Transform.translate(
                  offset: Offset(x1, y1),
                  child: Transform.rotate(
                    angle: angle1,
                    child: Opacity(
                      opacity: (1 - spiralVal * 1.2).clamp(0.0, 1.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withOpacity(0.2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.6),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.balance_rounded,
                          size: 42,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),

              // 4. العنصر القانوني الثاني: المطرقة 🔨 (تدور بالاتجاه المقابل وتتلاشى)
              if (spiralVal < 0.65)
                Transform.translate(
                  offset: Offset(x2, y2),
                  child: Transform.rotate(
                    angle: -angle2,
                    child: Opacity(
                      opacity: (1 - spiralVal * 1.2).clamp(0.0, 1.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.6),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.gavel_rounded,
                          size: 42,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                    ),
                  ),
                ),

              // 5. ظُهور اسم المنصة واسمك الكريم بعد الاصطدام 💥
              if (spiralVal > 0.45)
                Opacity(
                  opacity: impactVal.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: impactVal,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // أيقونة شعار متوهجة ثابته بالمنتصف
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2A2D3A), Color(0xFF111318)],
                            ),
                            border: Border.all(color: AppColors.accent, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.5 * glowVal),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.gavel_rounded,
                            size: 50,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // اسم المنصة مع خط ذهبي ذكي
                        const Text(
                          'مـنـصّـة الـقـانـون',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2.5,
                            shadows: [
                              Shadow(
                                color: AppColors.accent,
                                blurRadius: 15,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // فاصل مميز
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 30, height: 1, color: AppColors.accent.withOpacity(0.5)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(Icons.star, size: 12, color: AppColors.accent),
                            ),
                            Container(width: 30, height: 1, color: AppColors.accent.withOpacity(0.5)),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // اسمك الكريم مطعّم بتأثير ذكي أنيق
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFFFFD700),
                              Colors.white,
                              AppColors.accent,
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'سيدعباس عقيل الحسيني',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// 🎨 الرسام الخاص برسم المسارات الضوئية اللولبية والشرارات
class SpiralGlowPainter extends CustomPainter {
  final double progress;
  final double impactProgress;

  SpiralGlowPainter({required this.progress, required this.impactProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (progress < 0.65) {
      // رسم ذيل الحلقات اللولبية الضوئية
      double maxRadius = size.width * 0.45;
      Path path1 = Path();
      Path path2 = Path();

      for (double i = 0; i <= progress; i += 0.01) {
        double angle = i * 4 * pi;
        double r = (1 - i) * maxRadius;
        
        double x1 = center.dx + cos(angle) * r;
        double y1 = center.dy + sin(angle) * r;
        
        double x2 = center.dx + cos(angle + pi) * r;
        double y2 = center.dy + sin(angle + pi) * r;

        if (i == 0) {
          path1.moveTo(x1, y1);
          path2.moveTo(x2, y2);
        } else {
          path1.lineTo(x1, y1);
          path2.lineTo(x2, y2);
        }
      }

      paint.color = AppColors.accent.withOpacity(0.4);
      paint.strokeWidth = 3;
      canvas.drawPath(path1, paint);

      paint.color = const Color(0xFFFFD700).withOpacity(0.4);
      canvas.drawPath(path2, paint);
    }

    // رسم شرارات اصطدام ملفتة للانتباه عند نقطة التقاء العنصرين 💥
    if (progress > 0.45 && impactProgress < 0.9) {
      final sparkPaint = Paint()
        ..color = AppColors.accent.withOpacity(1.0 - impactProgress)
        ..strokeWidth = 2;

      final random = Random(42);
      for (int i = 0; i < 12; i++) {
        double sparkAngle = random.nextDouble() * 2 * pi;
        double sparkDist = impactProgress * 120 + random.nextDouble() * 30;
        
        Offset p1 = center + Offset(cos(sparkAngle) * (sparkDist * 0.3), sin(sparkAngle) * (sparkDist * 0.3));
        Offset p2 = center + Offset(cos(sparkAngle) * sparkDist, sin(sparkAngle) * sparkDist);

        canvas.drawLine(p1, p2, sparkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SpiralGlowPainter oldDelegate) => true;
}
