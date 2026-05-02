import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_reminder_page.dart';
import 'firebase_service.dart';

class MedsPage extends StatelessWidget {
  const MedsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F3F3),

        appBar: AppBar(
          title: const Text("الأدوية"),
          centerTitle: true,
        ),

        body: user == null
            ? const Center(child: Text("المستخدم غير مسجل دخول"))
            : StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.getRemindersStream(),
          builder: (context, snapshot) {

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text("لا يوجد أدوية بعد"),
              );
            }

            final meds = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: meds.length,
              itemBuilder: (context, index) {

                final doc = meds[index];
                final data = doc.data() as Map<String, dynamic>;

                final name = data['medicineName'] ?? "";

                final dose =
                    "${data['doseAmount'] ?? ""} ${data['doseUnit'] ?? ""}";

                // 🔥 تحسين الوقت
                final time = data['time'] != null
                    ? TimeOfDay.fromDateTime(
                  (data['time'] as Timestamp).toDate(),
                ).format(context)
                    : "";

                final imageUrl = data['imageUrl'] ?? "";
                final isActive = data['isActive'] ?? true;

                return _buildCard(
                  context,
                  doc,
                  name,
                  dose,
                  time,
                  imageUrl,
                  isActive,
                );
              },
            );
          },
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////
  Widget _buildCard(
      BuildContext context,
      QueryDocumentSnapshot doc,
      String name,
      String dose,
      String time,
      String imageUrl,
      bool isActive,
      ) {

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),

      child: Row(
        children: [

          /// 🖼️ صورة
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              width: 65,
              height: 65,
              fit: BoxFit.cover,
            )
                : Container(
              width: 65,
              height: 65,
              color: Colors.grey[200],
              child: const Icon(Icons.medication),
            ),
          ),

          const SizedBox(width: 12),

          /// 📄 البيانات
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    /// 🔥 تفعيل/إيقاف
                    Switch(
                      value: isActive,
                      onChanged: (val) async {
                        await FirebaseService.updateReminder(
                          docId: doc.id,
                          data: {
                            'isActive': val,
                          },
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Text(dose),
                    const SizedBox(width: 6),
                    const Text("|"),
                    const SizedBox(width: 6),
                    const Icon(Icons.access_time, size: 14),
                    const SizedBox(width: 4),
                    Text(time),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    /// ✏️ Edit
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateReminderPage(
                              docId: doc.id,
                              existingData:
                              doc.data() as Map<String, dynamic>,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        "Edit",
                        style: TextStyle(color: Colors.purple),
                      ),
                    ),

                    /// 🗑️ Delete (🔥 صار من FirebaseService)
                    GestureDetector(
                      onTap: () async {
                        await FirebaseService.deleteReminder(doc.id);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("تم حذف الدواء"),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}