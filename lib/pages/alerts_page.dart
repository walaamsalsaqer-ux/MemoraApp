import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    /// 🔴 إذا المستخدم مو مسجل
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("غير مسجل دخول"),
        ),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF5B2E91),

        body: SafeArea(
          child: Column(
            children: [

              const SizedBox(height: 20),

              /// 🔹 العنوان
              const Text(
                "التنبيهات",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              /// 🔹 القائمة
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),

                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("alerts")
                        .where("patientId", isEqualTo: user.uid)
                        .orderBy("timestamp", descending: true)
                        .snapshots(),

                    builder: (context, snapshot) {

                      /// ⏳ تحميل
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      /// ❌ مافيه بيانات
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text("لا توجد تنبيهات حتى الآن"),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {

                          final data =
                          docs[index].data() as Map<String, dynamic>;

                          final message = data["message"] ?? "تنبيه";
                          final timestamp = data["timestamp"];
                          final type = data["type"] ?? "general";

                          String formattedTime = "";

                          if (timestamp != null) {
                            final date =
                            (timestamp as Timestamp).toDate();
                            formattedTime =
                                DateFormat('dd/MM/yyyy - hh:mm a')
                                    .format(date);
                          }

                          /// 🎨 لون حسب النوع
                          Color color = Colors.blue;

                          if (type == "fall") {
                            color = Colors.red;
                          } else if (type == "safe_zone") {
                            color = Colors.orange;
                          } else if (type == "medication") {
                            color = Colors.green;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(14),
                            ),

                            child: Row(
                              children: [

                                Icon(
                                  Icons.notifications_active,
                                  color: color,
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [

                                      Text(
                                        message,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        formattedTime,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}