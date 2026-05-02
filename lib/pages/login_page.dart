import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscure = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    try {
      /// ✅ تسجيل الدخول (مرة وحدة فقط)
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      /// 🔥 الانتقال للهوم (المهم)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      debugPrint("LOGIN ERROR: ${e.code} - ${e.message}");

      String msg = "فشل تسجيل الدخول";
      if (e.code == "user-not-found") msg = "لا يوجد حساب بهذا البريد";
      if (e.code == "wrong-password") msg = "كلمة المرور غير صحيحة";
      if (e.code == "invalid-email") msg = "البريد غير صحيح";
      if (e.code == "invalid-credential") msg = "بيانات الدخول غير صحيحة";
      if (e.code == "network-request-failed") msg = "تحقق من الاتصال بالإنترنت";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF5B2E91),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // 🔥 حطيه هنا
                const SizedBox(height: 40),

                SizedBox(
                  height: 140,
                  child: Image.asset(
                    "assets/images/logo.png",
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  "Memora",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 25),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "تسجيل الدخول",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          "ادخلي بريدك وكلمة المرور",
                          style: TextStyle(color: Colors.black54),
                        ),

                        const SizedBox(height: 18),

                        /// 📧 الإيميل
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return "البريد مطلوب";

                            final ok = RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(v.trim());

                            return ok ? null : "اكتبي بريد صحيح";
                          },
                          decoration: InputDecoration(
                            labelText: "البريد الإلكتروني",
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        /// 🔒 الباسورد
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscure,
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return "كلمة المرور مطلوبة";

                            if (v.length < 6)
                              return "كلمة المرور لازم 6 أحرف أو أكثر";

                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: "كلمة المرور",
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => obscure = !obscure),
                              icon: Icon(obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// 🔘 زر الدخول
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B2E91),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white70,
                              disabledBackgroundColor:
                              const Color(0xFF5B2E91)
                                  .withOpacity(0.7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: isLoading ? null : login,
                            child: isLoading
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                                : const Text(
                              "دخول",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        /// 🔗 تسجيل
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("ما عندك حساب؟ "),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const RegisterPage(),
                                  ),
                                );
                              },
                              child: const Text("سجّلي الآن"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}