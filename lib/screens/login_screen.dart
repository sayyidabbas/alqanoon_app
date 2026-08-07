import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(

          gradient: LinearGradient(

            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,

            colors: [

              Color(0xff071320),
              Color(0xff05070D),
              Colors.black,

            ],
          ),
        ),

        child: SafeArea(

          child: Center(

            child: SingleChildScrollView(

              padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),

              child: Column(

                children: [

                  Container(

                    width: 120,
                    height: 120,

                    decoration: BoxDecoration(

                      shape: BoxShape.circle,

                      color: Colors.white.withOpacity(.05),

                      border: Border.all(

                        color: const Color(0xffD4AF37),
                        width: 2,

                      ),

                      boxShadow: [

                        BoxShadow(

                          color: Colors.blue.withOpacity(.20),
                          blurRadius: 30,

                        ),

                      ],
                    ),

                    child: const Icon(

                      Icons.gavel_rounded,

                      color: Color(0xffD4AF37),

                      size: 60,

                    ),
                  ),

                  const SizedBox(height: 35),

                  const Text(

                    "منصة القانون",

                    style: TextStyle(

                      color: Color(0xffD4AF37),

                      fontSize: 32,

                      fontWeight: FontWeight.bold,

                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(

                    "تسجيل الدخول",

                    style: TextStyle(

                      color: Colors.white70,

                      fontSize: 18,

                    ),
                  ),

                  const SizedBox(height: 40),

                  TextField(

                    controller: usernameController,

                    style: const TextStyle(
                      color: Colors.white,
                    ),

                    decoration: InputDecoration(

                      hintText: "اسم المستخدم",

                      hintStyle: const TextStyle(
                        color: Colors.white54,
                      ),

                      prefixIcon: const Icon(
                        Icons.person,
                        color: Color(0xffD4AF37),
                      ),

                      filled: true,

                      fillColor: Colors.white.withOpacity(.05),

                      enabledBorder: OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(18),

                        borderSide: BorderSide(

                          color:
                              Colors.white.withOpacity(.15),

                        ),
                      ),

                      focusedBorder: OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(18),

                        borderSide: const BorderSide(

                          color: Color(0xffD4AF37),
                          width: 2,

                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(

                    controller: passwordController,

                    obscureText: obscurePassword,

                    style: const TextStyle(
                      color: Colors.white,
                    ),

                    decoration: InputDecoration(

                      hintText: "كلمة المرور",

                      hintStyle: const TextStyle(
                        color: Colors.white54,
                      ),

                      prefixIcon: const Icon(

                        Icons.lock,

                        color: Color(0xffD4AF37),

                      ),

                      suffixIcon: IconButton(

                        onPressed: () {

                          setState(() {

                            obscurePassword =
                                !obscurePassword;

                          });

                        },

                        icon: Icon(

                          obscurePassword

                              ? Icons.visibility

                              : Icons.visibility_off,

                          color: Colors.white70,

                        ),
                      ),

                      filled: true,

                      fillColor: Colors.white.withOpacity(.05),

                      enabledBorder: OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(18),

                        borderSide: BorderSide(

                          color:
                              Colors.white.withOpacity(.15),

                        ),
                      ),

                      focusedBorder: OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(18),

                        borderSide: const BorderSide(

                          color: Color(0xffD4AF37),
                          width: 2,

                        ),
                      ),
                    ),
                  ),
                                    const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () {

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "سيتم ربط تسجيل الدخول لاحقًا",
                            ),
                          ),
                        );

                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffD4AF37),
                        foregroundColor: Colors.black,
                        elevation: 12,
                        shadowColor: const Color(0xffD4AF37),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        "تسجيل الدخول",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: OutlinedButton(
                      onPressed: () {

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "سيتم إنشاء صفحة التسجيل لاحقًا",
                            ),
                          ),
                        );

                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xffD4AF37),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        "إنشاء حساب",
                        style: TextStyle(
                          color: Color(0xffD4AF37),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    "© منصة القانون\nسيدعباس عقيل الحسيني",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
