import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class FirebaseService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /////////////////////////////////////////////////////////
  // 🔥 userId (آمن)
  /////////////////////////////////////////////////////////
  static String? get userId => _auth.currentUser?.uid;

  static DocumentReference? get userDoc =>
      userId == null ? null : _db.collection("users").doc(userId);

  /////////////////////////////////////////////////////////
  // 👤 بيانات المستخدم
  /////////////////////////////////////////////////////////
  static Future<Map<String, dynamic>?> getUserData() async {
    if (userDoc == null) return null;
    final doc = await userDoc!.get();
    return doc.data() as Map<String, dynamic>?;
  }

  static Stream<DocumentSnapshot>? getUserDataStream() {
    if (userDoc == null) return null;
    return userDoc!.snapshots();
  }

  /////////////////////////////////////////////////////////
  // 📍 السيف زون
  /////////////////////////////////////////////////////////

  /// 💾 حفظ منطقة واحدة (للـ watch)
  static Future<void> saveSafeZone({
    required double lat,
    required double lng,
    required double radius,
    String name = "المنطقة الآمنة",
  }) async {
    if (userDoc == null) return;

    await userDoc!
        .collection("config")
        .doc("safe_zone")
        .set({
      "lat": lat,
      "lng": lng,
      "radius": radius,
      "name": name,
      "isActive": true, // 🔥 مهم للساعة
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// 🔥 حفظ كل المناطق
  static Future<void> saveSafeZonesList({
    required List<Map<String, dynamic>> zones,
  }) async {
    if (userDoc == null) return;

    await userDoc!.set({
      "safeZones": zones,
    }, SetOptions(merge: true));

    /// ⌚ إرسال أول منطقة للساعة
    if (zones.isNotEmpty) {
      final first = zones.first;

      await saveSafeZone(
        lat: first["lat"],
        lng: first["lng"],
        radius: first["radius"],
        name: first["name"] ?? "المنطقة",
      );
    }
  }

  /// 📥 جلب المناطق
  static Future<List<Map<String, dynamic>>> getSafeZonesList() async {
    if (userDoc == null) return [];

    final doc = await userDoc!.get();

    if (!doc.exists) return [];

    final data = doc.data() as Map<String, dynamic>?;

    if (data == null || data["safeZones"] == null) return [];

    return List<Map<String, dynamic>>.from(data["safeZones"]);
  }

  /// 🗑️ حذف منطقة
  static Future<void> deleteZone(int index) async {
    final zones = await getSafeZonesList();

    if (index >= zones.length) return;

    zones.removeAt(index);

    await saveSafeZonesList(zones: zones);
  }

  /// 📡 Stream للسيف زون (آمن)
  static Stream<DocumentSnapshot> getSafeZoneStream() {
    if (userDoc == null) {
      return const Stream.empty();
    }

    return userDoc!
        .collection("config")
        .doc("safe_zone")
        .snapshots();
  }

  /// 📥 قراءة مرة وحدة
  static Future<Map<String, dynamic>?> getSafeZoneOnce() async {
    if (userDoc == null) return null;

    final doc = await userDoc!
        .collection("config")
        .doc("safe_zone")
        .get();

    if (!doc.exists) return null;

    return doc.data() as Map<String, dynamic>;
  }

  /// 🧠 هل داخل المنطقة؟
  static Future<bool> isInsideSafeZone() async {
    final zone = await getSafeZoneOnce();
    if (zone == null) return false;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final distance = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      zone["lat"],
      zone["lng"],
    );

    return distance <= zone["radius"];
  }

  /////////////////////////////////////////////////////////
  // 💊 الأدوية
  /////////////////////////////////////////////////////////
  static Future<void> addReminder({
    required String name,
    required DateTime time,
    required int dose,
    required String unit,
    String? imageUrl,
    String? audioUrl,
  }) async {
    if (userDoc == null) return;

    await userDoc!.collection("reminders").add({
      "medicineName": name,
      "time": Timestamp.fromDate(time),
      "doseAmount": dose,
      "doseUnit": unit,
      "imageUrl": imageUrl ?? "",
      "audioUrl": audioUrl ?? "",
      "forWatch": true,
      "isActive": true,
      "createdAt": FieldValue.serverTimestamp(),
    });

    await _updateNextMedForWatch();
  }

  static Future<void> updateReminder({
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    if (userDoc == null) return;

    await userDoc!
        .collection("reminders")
        .doc(docId)
        .update(data);

    await _updateNextMedForWatch();
  }

  static Future<void> deleteReminder(String docId) async {
    if (userDoc == null) return;

    await userDoc!
        .collection("reminders")
        .doc(docId)
        .delete();

    await _updateNextMedForWatch();
  }

  /////////////////////////////////////////////////////////
  // 🔥 تحديث أقرب دواء للساعة
  /////////////////////////////////////////////////////////
  static Future<void> _updateNextMedForWatch() async {
    if (userDoc == null) return;

    final next = await getNextMed();

    if (next != null) {
      await userDoc!
          .collection("watch_data")
          .doc("next_med")
          .set({
        "name": next["medicineName"] ?? next["name"],
        "time": next["time"],
      });
    } else {
      await userDoc!
          .collection("watch_data")
          .doc("next_med")
          .delete();
    }
  }

  /////////////////////////////////////////////////////////
  // 🚨 تنبيهات
  /////////////////////////////////////////////////////////
  static Future<void> addAlert({
    required String type,
    required String message,
  }) async {
    if (userDoc == null) return;

    await userDoc!.collection("alerts").add({
      "type": type,
      "message": message,
      "time": FieldValue.serverTimestamp(),
      "read": false,
      "source": "mobile",
    });
  }

  static Future<void> sendFallAlert() async {
    await addAlert(
      type: "fall",
      message: "🚨 تم اكتشاف سقوط",
    );
  }

  static Future<void> sendSafeZoneAlert() async {
    await addAlert(
      type: "safe_zone",
      message: "🚨 تم الخروج من المنطقة الآمنة",
    );
  }

  /////////////////////////////////////////////////////////
  // ⌚ حالة الساعة
  /////////////////////////////////////////////////////////
  static Future<void> updateWatchStatus({
    required String status,
    required int battery,
  }) async {
    if (userDoc == null) return;

    await userDoc!
        .collection("devices")
        .doc("watch_001")
        .set({
      "status": status,
      "battery": battery,
      "lastSeen": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /////////////////////////////////////////////////////////
  // 📡 Streams
  /////////////////////////////////////////////////////////
  static Stream<QuerySnapshot>? getRemindersStream() {
    if (userDoc == null) return null;

    return userDoc!
        .collection("reminders")
        .orderBy("time")
        .snapshots();
  }

  static Stream<QuerySnapshot>? getAlertsStream() {
    if (userDoc == null) return null;

    return userDoc!
        .collection("alerts")
        .orderBy("time", descending: true)
        .snapshots();
  }

  /////////////////////////////////////////////////////////
  // 💊 أقرب دواء
  /////////////////////////////////////////////////////////
  static Future<Map<String, dynamic>?> getNextMed() async {
    if (userDoc == null) return null;

    final now = Timestamp.now();

    final snap = await userDoc!
        .collection("reminders")
        .where("time", isGreaterThan: now)
        .orderBy("time")
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    return snap.docs.first.data();
  }

  /////////////////////////////////////////////////////////
  // 🔗 ربط الساعة
  /////////////////////////////////////////////////////////
  static Future<String> pairWatch(String codeValue) async {

    final docRef =
    _db.collection('pairing_codes').doc(codeValue);

    final doc = await docRef.get();

    if (!doc.exists) return "❌ الكود غير موجود";

    final data = doc.data() as Map<String, dynamic>;

    if (data["paired"] == true) return "❌ الكود مستخدم";

    final user = _auth.currentUser;
    if (user == null) return "❌ لازم تسجل دخول";

    await docRef.update({
      "paired": true,
      "userId": user.uid,
      "pairedAt": FieldValue.serverTimestamp(),
    });

    await userDoc!
        .collection('devices')
        .doc(codeValue)
        .set({
      "status": "connected",
      "lastSeen": FieldValue.serverTimestamp(),
    });

    await userDoc!.update({
      "pairedCode": codeValue,
    });

    return "✅ تم الربط";
  }
}