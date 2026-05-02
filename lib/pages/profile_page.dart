import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'enter_code_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  //////////////////////////////////////////////////////
  // 🚪 تسجيل خروج
  //////////////////////////////////////////////////////
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  //////////////////////////////////////////////////////
  // ✏️ تعديل البيانات (BottomSheet احترافي)
  //////////////////////////////////////////////////////
  void editData(BuildContext context, User user, Map data) {

    final name = TextEditingController(text: data["patientName"]);
    final age = TextEditingController(text: data["age"].toString());
    String gender = data["gender"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Text(
                  "تعديل البيانات",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: "اسم المريض",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: age,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "العمر",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: gender,
                  items: const [
                    DropdownMenuItem(value: "ذكر", child: Text("ذكر")),
                    DropdownMenuItem(value: "أنثى", child: Text("أنثى")),
                  ],
                  onChanged: (v) => gender = v!,
                  decoration: InputDecoration(
                    labelText: "الجنس",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({
                      "patientName": name.text,
                      "age": int.parse(age.text),
                      "gender": gender,
                    });

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("حفظ"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //////////////////////////////////////////////////////
  // 📊 عنصر إحصائية
  //////////////////////////////////////////////////////
  Widget statItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6A1B9A)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  //////////////////////////////////////////////////////
  // UI
  //////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F4FB),

        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .snapshots(),
          builder: (context, snap) {

            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snap.data!.data() as Map<String, dynamic>;

            final name = data["patientName"] ?? "بدون اسم";
            final caregiver = data["caregiverName"] ?? "-";
            final age = data["age"] ?? "-";
            final gender = data["gender"] ?? "-";

            final today = DateTime.now();
            final startOfDay = DateTime(today.year, today.month, today.day);

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('devices')
                  .doc("watch")
                  .snapshots(),
              builder: (context, deviceSnap) {

                final d = deviceSnap.data?.data() as Map<String, dynamic>?;

                final lastSeen = d?["lastSeen"];
                final battery = d?["battery"] ?? 0;

                bool connected = false;

                if (lastSeen != null) {
                  final diff = DateTime.now()
                      .difference((lastSeen as Timestamp).toDate())
                      .inSeconds;
                  connected = diff < 10;
                }

                return ListView(
                  children: [

                    //////////////////////////////////////////////////////
                    // 💜 Header
                    //////////////////////////////////////////////////////
                    Container(
                      padding: const EdgeInsets.only(top: 60, bottom: 30),
                      decoration: const BoxDecoration(
                        color: Color(0xFF5B2E91),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [

                          const CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person),
                          ),

                          const SizedBox(height: 12),

                          Text(name,
                              style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),

                          Text("مُقدِّم رعاية: $caregiver",
                              style: const TextStyle(color: Colors.white70)),

                          Text("العمر: $age - $gender",
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    //////////////////////////////////////////////////////
                    // 🔌 اتصال
                    //////////////////////////////////////////////////////
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6)
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            connected ? Icons.watch : Icons.watch_off,
                            color: connected ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            connected ? "متصل بالساعة" : "غير متصل",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: connected ? Colors.green : Colors.red,
                            ),
                          ),
                          const Spacer(),
                          Text("🔋 $battery%"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    //////////////////////////////////////////////////////
                    // 📊 إحصائيات (حقيقية)
                    //////////////////////////////////////////////////////
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('reminders')
                          .where('time',
                          isGreaterThanOrEqualTo:
                          Timestamp.fromDate(startOfDay))
                          .snapshots(),
                      builder: (context, medSnap) {

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('alerts')
                              .where('userId', isEqualTo: user.uid)
                              .where('type', isEqualTo: 'fall')
                              .where('createdAt',
                              isGreaterThanOrEqualTo:
                              Timestamp.fromDate(startOfDay))
                              .snapshots(),
                          builder: (context, fallSnap) {

                            int medsCount = medSnap.data?.docs.length ?? 0;
                            int fallCount = fallSnap.data?.docs.length ?? 0;

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black12, blurRadius: 6)
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  const Text("إحصائيات اليوم",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),

                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      statItem(Icons.medication, "الأدوية",
                                          medsCount.toString()),
                                      statItem(Icons.warning, "السقوط",
                                          fallCount.toString()),
                                      statItem(Icons.location_on, "الموقع",
                                          "داخل"),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    //////////////////////////////////////////////////////
                    // 🔗 إعادة اقتران (فخم 💜)
                    //////////////////////////////////////////////////////
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EnterCodePage()),
                          );
                        },
                        icon: const Icon(Icons.sync),
                        label: const Text("إعادة الاقتران"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEDE7F6),
                          foregroundColor: const Color(0xFF6A1B9A),
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    //////////////////////////////////////////////////////
                    // ✏️ تعديل
                    //////////////////////////////////////////////////////
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        onPressed: () => editData(context, user, data),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A1B9A),
                        ),
                        child: const Text("تعديل البيانات"),
                      ),
                    ),

                    const SizedBox(height: 12),

                    //////////////////////////////////////////////////////
                    // 🚪 خروج (فخم 🔥)
                    //////////////////////////////////////////////////////
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton.icon(
                        onPressed: () => logout(context),
                        icon: Icon(Icons.logout,
                            color: Colors.red.shade700),
                        label: Text(
                          "تسجيل الخروج",
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade100,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}