import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'enter_code_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final patientNameController = TextEditingController();
  final ageController = TextEditingController();

  String? selectedGender;
  bool isLoading = false;

  Future<void> goToPairing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;


      /// 🔥 نحفظ الاسم في Auth
      await user!.updateDisplayName(nameController.text.trim());
      await user.reload();

      /// 🔥 نحفظ البيانات في Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        "caregiverName": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "patientName": patientNameController.text.trim(),
        "age": int.tryParse(ageController.text.trim()) ?? 0, // ✅ FIX
        "gender": selectedGender,
        "paired": false,

        /// 🔥 هذا الجديد (مهم جدًا)
        "pairedCode": null,

        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const EnterCodePage(),
        ),
      );
    } catch (e) {
  print("🔥 ERROR: $e");

  String msg = "خطأ في التسجيل";

  if (e is FirebaseAuthException) {
  if (e.code == "email-already-in-use") {
  msg = "الإيميل مستخدم من قبل";
  } else if (e.code == "invalid-email") {
  msg = "الإيميل غير صحيح";
  } else if (e.code == "weak-password") {
  msg = "كلمة المرور ضعيفة";
  } else if (e.code == "operation-not-allowed") {
  msg = "فعّلي Email/Password من Firebase";
  } else {
  msg = e.message ?? msg;
  }
  }

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(msg)),
  );

  }
    finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    patientNameController.dispose();
    ageController.dispose();
    super.dispose();
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
              children: [
                const SizedBox(height: 20),

                Image.asset(
                  "assets/images/logo.png",
                  height: 80,
                ),

                const SizedBox(height: 10),

                const Text(
                  "Memora",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔥 الكارد الأبيض
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [

                        _field("الاسم", nameController),

                        _field(
                          "البريد الإلكتروني",
                          emailController,
                          keyboard: TextInputType.emailAddress,
                        ),

                        _field(
                          "رقم الجوال",
                          phoneController,
                          keyboard: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),

                        _field(
                          "كلمة المرور",
                          passwordController,
                          isPassword: true,
                        ),

                        _field("اسم المريض", patientNameController),

                        DropdownButtonFormField<String>(
                          value: selectedGender,
                          decoration: const InputDecoration(
                            labelText: "الجنس",
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: "ذكر",
                              child: Text("ذكر"),
                            ),
                            DropdownMenuItem(
                              value: "أنثى",
                              child: Text("أنثى"),
                            ),
                          ],
                          onChanged: (v) => setState(() => selectedGender = v),
                          validator: (v) =>
                          v == null ? "اختاري الجنس" : null,
                        ),

                        const SizedBox(height: 10),

                        _field(
                          "العمر",
                          ageController,
                          keyboard: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : goToPairing,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A1B9A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                                : const Text("إنشاء حساب"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
      String label,
      TextEditingController controller, {
        bool isPassword = false,
        TextInputType? keyboard,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return "$label مطلوب"; // ✅ FIX
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}