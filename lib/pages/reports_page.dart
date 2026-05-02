import 'package:flutter/material.dart';
import 'safe_zone.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'firebase_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {

  bool isInsideSafeZone = true;
  bool isLoading = true;
  String zoneName = "غير محدد";

  LatLng currentLocation = const LatLng(25.3833, 49.5861);

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await getCurrentLocation();
      await checkSafeZoneStatus();
    });
  }

  /////////////////////////////////////////////////////////
  Future<void> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => isLoading = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 5));

      if (!mounted) return;

      setState(() {
        currentLocation = LatLng(pos.latitude, pos.longitude);
      });

    } catch (e) {
      setState(() {
        currentLocation = const LatLng(25.3833, 49.5861);
      });
    }
  }

  /////////////////////////////////////////////////////////
  Future<void> checkSafeZoneStatus() async {
    try {
      final zone = await FirebaseService.getSafeZoneOnce();

      if (zone == null) {
        setState(() => isLoading = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 5));

      final distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        zone["lat"],
        zone["lng"],
      );

      setState(() {
        zoneName = zone["name"] ?? "المنطقة";
        isInsideSafeZone = distance <= zone["radius"];
        isLoading = false;
      });

    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  /////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("يرجى تسجيل الدخول")),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF5B2E91),

        body: SafeArea(
          child: Column(
            children: [

              const SizedBox(height: 20),

              const Text(
                "التقارير",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
                  ),

                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /////////////////////////////////////////////////////////
                        /// 🚨 التنبيه
                        /////////////////////////////////////////////////////////
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('alerts')
                              .orderBy('time', descending: true)
                              .limit(1)
                              .snapshots(),
                          builder: (context, snapshot) {

                            if (snapshot.hasData &&
                                snapshot.data!.docs.isNotEmpty) {

                              final alert = snapshot.data!.docs.first.data()
                              as Map<String, dynamic>;

                              if (alert["type"] == "safe_zone") {
                                Future.microtask(() {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(alert["message"]),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                });
                              }
                            }

                            return const SizedBox();
                          },
                        ),

                        /////////////////////////////////////////////////////////
                        /// 📊 الكروت
                        /////////////////////////////////////////////////////////
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryCard(
                                title: "الحالة",
                                value: isLoading
                                    ? "..."
                                    : isInsideSafeZone
                                    ? "داخل المنطقة"
                                    : "خارج المنطقة",
                                color: isInsideSafeZone
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryCard(
                                title: "الموقع",
                                value: zoneName,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          "موقع المريض",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 10),

                        /////////////////////////////////////////////////////////
                        /// 🗺️ الخريطة (تم إصلاح الضغط)
                        /////////////////////////////////////////////////////////
                        SizedBox(
                          height: 170,
                          child: Stack(
                            children: [

                              /// الخريطة
                              IgnorePointer(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: currentLocation,
                                      zoom: 15,
                                    ),
                                    myLocationEnabled: true,
                                    zoomControlsEnabled: true,
                                  ),
                                ),
                              ),

                              /// طبقة الضغط
                              Positioned.fill(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SafeZonePage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        /////////////////////////////////////////////////////////
                        /// ⚠️ السقوط
                        /////////////////////////////////////////////////////////
                        const Text(
                          "سجل السقوط",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 10),

                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('patients')
                              .doc(user.uid)
                              .collection('falls')
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {

                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (snapshot.data!.docs.isEmpty) {
                              return const Text("لا يوجد سجل سقوط");
                            }

                            return Column(
                              children: snapshot.data!.docs.map((doc) {

                                final data =
                                doc.data() as Map<String, dynamic>;
                                final ts = data['timestamp'];

                                return FallCard(
                                  date:
                                  "${ts.toDate().day}/${ts.toDate().month}",
                                  time:
                                  "${ts.toDate().hour}:${ts.toDate().minute}",
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
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

/////////////////////////////////////////////////////////

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/////////////////////////////////////////////////////////

class FallCard extends StatelessWidget {
  final String date;
  final String time;

  const FallCard({
    super.key,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("حادثة سقوط"),
          Text(date),
          Text("الوقت: $time"),
        ],
      ),
    );
  }
}