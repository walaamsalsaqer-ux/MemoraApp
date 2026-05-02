import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'profile_page.dart';
import 'reports_page.dart';
import 'meds_page.dart';
import 'create_reminder_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final user = FirebaseAuth.instance.currentUser!;

    final ref = FirebaseStorage.instance
        .ref()
        .child("profile_images/${user.uid}.jpg");

    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await user.updatePhotoURL(url);
    await user.reload();

    setState(() {});
  }

  void _goToTab(int index) {
    setState(() => currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("لم يتم تسجيل الدخول")),
      );
    }

    final pages = [
      DashboardTab(user: user, onPickImage: _pickAndUploadImage),
      const MedsPage(),
      ReportsPage(),
      const ProfilePage(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
        body: pages[currentIndex],

        /// زر +
        floatingActionButton: Transform.translate(
          offset: const Offset(0, 8),
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF6A1B9A),
            elevation: 6,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateReminderPage(),
                ),
              );
            },
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ),
        floatingActionButtonLocation:
        FloatingActionButtonLocation.centerDocked,

        /// Bottom Bar (رجعت الأسماء)
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                navItem(Icons.home, 0, "الرئيسية"),
                navItem(Icons.medication, 1, "الأدوية"),
                const SizedBox(width: 40),
                navItem(Icons.bar_chart, 2, "التقارير"),
                navItem(Icons.person, 3, "الملف الشخصي"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget navItem(IconData icon, int index, String label) {
    final active = currentIndex == index;

    return GestureDetector(
      onTap: () => _goToTab(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: active ? const Color(0xFF6A1B9A) : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: active ? const Color(0xFF6A1B9A) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////

class DashboardTab extends StatefulWidget {
  final User user;
  final VoidCallback onPickImage;

  const DashboardTab({
    super.key,
    required this.user,
    required this.onPickImage,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

// 🔥 فقط الجزء المعدل داخل DashboardTab

class _DashboardTabState extends State<DashboardTab> {
  bool? insideZone;
  String nextMed = "لا يوجد تذكير";
  String medStatus = "";
  StreamSubscription? medSub;
  StreamSubscription? statusSub;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _listenAll();
  }

  @override
  void dispose() {
    medSub?.cancel();
    statusSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  //////////////////////////////////////////////////////
  // 🔥 ربط مباشر (بدل التايمر)
  //////////////////////////////////////////////////////

    void _listenAll() {
      /// 💊 الدواء القادم
      medSub = FirebaseFirestore.instance
          .collection("users")
          .doc(widget.user.uid)
          .collection("watch_data")
          .doc("next_med")
          .snapshots()
          .listen((doc) {

        if (doc.exists) {
          final data = doc.data()!;
          final name = data["name"] ?? "";
          final time = (data["time"] as Timestamp?)?.toDate();

          setState(() {
            nextMed = name;

            if (time != null) {
              nextMed =
              "$name\n${time.hour}:${time.minute.toString().padLeft(2, '0')}";
            }
          });
        }
      });

      /// ✅ حالة الدواء (مع إنشاء إذا مو موجود)
      statusSub = FirebaseFirestore.instance
          .collection("users")
          .doc(widget.user.uid)
          .collection("watch_data")
          .doc("med_status")
          .snapshots()
          .listen((doc) {

        /// 🔥 إذا ما موجود → أنشئه
        if (!doc.exists) {
          FirebaseFirestore.instance
              .collection("users")
              .doc(widget.user.uid)
              .collection("watch_data")
              .doc("med_status")
              .set({
            "name": "",
            "taken": false,
            "time": null,
          });
          return;
        }

        final data = doc.data();
        if (data != null) {
          final taken = data["taken"];

          setState(() {
            medStatus =
            taken == true ? "تم أخذ الدواء" : "لم يتم أخذ الدواء";
          });
        }
      });

      /// 📍 السيف زون (يتحدث كل 5 ثواني)
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        _checkZone();
      });
    }

  //////////////////////////////////////////////////////
  Future<void> _checkZone() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.user.uid)
        .collection("config")
        .doc("safe_zone")
        .get();

    if (!doc.exists) {
      setState(() => insideZone = null);
      return;
    }

    final data = doc.data()!;
    final pos = await Geolocator.getCurrentPosition();

    final distance = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      data["lat"],
      data["lng"],
    );

    setState(() => insideZone = distance <= (data["radius"] ?? 100));
  }

  //////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        /// HEADER
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(widget.user.uid)
              .snapshots(),
          builder: (context, snapshot) {

            final data =
            snapshot.data?.data() as Map<String, dynamic>?;

            final name = data?["patientName"] ?? "مستخدم";
            final caregiver = data?["caregiverName"] ?? "";

            return Container(
              padding: const EdgeInsets.only(
                  top: 60, left: 20, right: 20, bottom: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [

                  Expanded(
                    child: Row(
                      children: [

                        GestureDetector(
                          onTap: widget.onPickImage,
                          child: const CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person,
                                color: Colors.white),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [

                            Text(name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight:
                                    FontWeight.bold)),

                            Text("مقدم رعاية: $caregiver",
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12)),

                            const SizedBox(height: 4),

                            /// 🔥 الاتصال الحقيقي
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(widget.user.uid)
                                  .collection("devices")
                                  .doc("watch")
                                  .snapshots(),
                              builder: (context, snap) {

                                final d = snap.data?.data()
                                as Map<String, dynamic>?;

                                final lastSeen = d?["lastSeen"];

                                bool connected = false;

                                if (lastSeen != null) {
                                  final diff = DateTime.now()
                                      .difference((lastSeen
                                  as Timestamp)
                                      .toDate())
                                      .inSeconds;

                                  connected = diff < 15;
                                }

                                return Row(
                                  children: [
                                    Icon(Icons.circle,
                                        size: 8,
                                        color: connected
                                            ? Colors.green
                                            : Colors.red),
                                    const SizedBox(width: 5),
                                    Text(
                                      connected
                                          ? "متصل بالساعة"
                                          : "غير متصل",
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Icon(Icons.notifications,
                      color: Colors.white),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        /// BODY
        Expanded(
          child: ListView(
            padding:
            const EdgeInsets.symmetric(horizontal: 20),
            children: [

              /// 📊 الإحصائيات
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .doc(widget.user.uid)
                    .collection("reminders")
                    .snapshots(),
                builder: (context, snapshot) {

                  final count =
                      snapshot.data?.docs.length ?? 0;

                  final zoneText = insideZone == null
                      ? "جاري التحقق..."
                      : (insideZone!
                      ? "داخل المنطقة"
                      : "خارج المنطقة");

                  return buildCard(
                    "الإحصائيات اليومية",
                    "عدد الأدوية: $count\n$zoneText",
                    Icons.insights,
                  );
                },
              ),

              /// 💊 التذكيرات (من الساعة)
              buildCard(
                "التذكيرات",
                "$nextMed\n$medStatus",
                Icons.access_time,
              ),


              /// 📍 المنطقة الآمنة
              buildCard(
                "المنطقة الآمنة",
                insideZone == null
                    ? "جاري التحقق..."
                    : (insideZone!
                    ? "داخل المنطقة"
                    : "خارج المنطقة"),
                Icons.shield,
              ),

              /// 🚨 السقوط
              buildCard(
                "سجل السقوط",
                "لا يوجد سقوط",
                Icons.history,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildCard(
      String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
              const Color(0xFF6A1B9A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
            Icon(icon, color: const Color(0xFF6A1B9A)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 5),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

