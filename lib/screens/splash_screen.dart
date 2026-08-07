import 'dart:async';

import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _titleController;
  late AnimationController _nameController;
  late AnimationController _glowController;

  late Animation<double> _titleOpacity;
  late Animation<double> _titleScale;

  late Animation<double> _nameOpacity;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _nameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _titleOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: Curves.easeOut,
      ),
    );

    _titleScale = Tween<double>(
      begin: 0.70,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: Curves.elasticOut,
      ),
    );

    _nameOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _nameController,
        curve: Curves.easeIn,
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 70,
      end: 150,
    ).animate(_glowController);

    _startAnimation();
  }

  Future<void> _startAnimation() async {

    _titleController.forward();

    await Future.delayed(
      const Duration(milliseconds: 900),
    );

    _nameController.forward();

    await Future.delayed(
      const Duration(seconds: 3),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Stack(

        children: [

          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [

                  Color(0xff08111F),
                  Color(0xff05070D),
                  Colors.black,

                ],
              ),
            ),
          ),

          Center(
            child: AnimatedBuilder(

              animation: _glowAnimation,

              builder: (_, __) {

                return Container(

                  width: _glowAnimation.value * 2,
                  height: _glowAnimation.value * 2,

                  decoration: BoxDecoration(

                    shape: BoxShape.circle,

                    boxShadow: [

                      BoxShadow(

                        color: Colors.blue.withOpacity(.18),
                        blurRadius: _glowAnimation.value,

                        spreadRadius:
                            _glowAnimation.value / 2,

                      ),

                    ],
                  ),
                );
              },
            ),
          ),
                    Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                FadeTransition(
                  opacity: _titleOpacity,
                  child: ScaleTransition(
                    scale: _titleScale,
                    child: const Text(
                      "أهلاً بكم في منصة القانون",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xffD4AF37),
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                FadeTransition(
                  opacity: _nameOpacity,
                  child: const Text(
                    "سيدعباس عقيل الحسيني",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 220),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Container(
                      width: value,
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xffD4AF37),
                            Colors.white,
                            Color(0xffD4AF37),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
