import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EnterCodePage extends StatefulWidget {
  const EnterCodePage({super.key});

  @override
  State<EnterCodePage> createState() => _EnterCodePageState();
}

class _EnterCodePageState extends State<EnterCodePage> {

  final codeController = TextEditingController();
  String message = "";

  String code = "";
  bool isComplete = false;

  //////////////////////////////////////////////////////
  // 🔥 الربط
  //////////////////////////////////////////////////////
  Future<void> pairWatch() async {

    final codeValue = code.trim();

    if (codeValue.isEmpty) {
      setState(() => message = "⚠️ أدخل الكود");
      return;
    }

    try {

      final docRef = FirebaseFirestore.instance
          .collection('pairing_codes')
          .doc(codeValue);

      final doc = await docRef.get();

      if (!doc.exists) {
        setState(() => message = "❌ الكود غير موجود");
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      if (data["paired"] == true) {
        setState(() => message = "❌ الكود مستخدم");
        return;
      }

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() => message = "❌ لازم تسجل دخول");
        return;
      }

      await docRef.update({
        "paired": true,
        "userId": user.uid,
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc("watch_001")
          .set({
        "status": "connected",
        "lastSeen": FieldValue.serverTimestamp(),
        "userId": user.uid,
      });

      setState(() => message = "✅ تم الربط");

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, '/home');
      });

    } catch (e) {
      setState(() => message = "❌ خطأ في الربط");
    }
  }
  //////////////////////////////////////////////////////
  // 🔢 OTP UI
  //////////////////////////////////////////////////////
  Widget buildOTPField() {
    return Column(
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 40,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: index < code.length
                      ? const Color(0xFF6A1B9A)
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Text(
                index < code.length ? code[index] : "",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 10),

        // ✅ علامة صح
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isComplete ? 1 : 0,
          child: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 28,
          ),
        ),

        // 🔥 TextField مخفي
        SizedBox(
          height: 0,
          child: TextField(
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            onChanged: (value) {
              if (value.length <= 6) {
                setState(() {
                  code = value;
                  codeController.text = value;
                  isComplete = value.length == 6;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  //////////////////////////////////////////////////////
  // UI
  //////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              "ربط الساعة",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A1B9A),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "أدخل الكود الظاهر في الساعة",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 25),

            buildOTPField(),

            const SizedBox(height: 25),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: isComplete ? pairWatch : null,
              child: const Text("ربط"),
            ),

            const SizedBox(height: 20),

            Text(message),
          ],
        ),
      ),
    );
  }
}