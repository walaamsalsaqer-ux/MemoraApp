import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memora_app/cloudinary_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';

class CreateReminderPage extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;

  const CreateReminderPage({
    super.key,
    this.docId,
    this.existingData,
  });

  @override
  State<CreateReminderPage> createState() => _CreateReminderPageState();
}

class _CreateReminderPageState extends State<CreateReminderPage> {
  @override
  void initState() {
    super.initState();
    recorder = FlutterSoundRecorder();   // 🔥 مهم
    initRecorder();                      // 🔥 مهم

    if (widget.existingData != null) {
      final data = widget.existingData!;

      medicineNameController.text = data['medicineName'] ?? "";

      startDate = (data['startDate'] as Timestamp?)?.toDate();
      endDate = (data['endDate'] as Timestamp?)?.toDate();

      final time = (data['time'] as Timestamp?)?.toDate();
      if (time != null) {
        selectedTime = TimeOfDay(hour: time.hour, minute: time.minute);
      }

      doseAmount = data['doseAmount'] ?? 1;
      doseUnit = data['doseUnit'] ?? "حبة";
      afterMeal = data['afterMeal'] ?? true;
      imageUrl = data['imageUrl'];
      audioUrl = data['audioUrl'];
    }
  }
  final medicineNameController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? selectedTime;
  String? audioPath;
  FlutterSoundRecorder? recorder;
  bool isRecording = false;
  String? audioUrl;
  final AudioPlayer player = AudioPlayer();
  bool isPlaying = false;

  bool afterMeal = true;
  bool isLoading = false;

  File? selectedImage;
  String? imageUrl;

  final ImagePicker _picker = ImagePicker();

  int doseAmount = 1;
  String doseUnit = "حبة";

  Widget greyBox({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: child,
      ),
    );
  }
  Future<void> initRecorder() async {
    await Permission.microphone.request();
    await recorder!.openRecorder();
  }
  Future<void> startRecording() async {

    final dir = await Directory.systemTemp.createTemp();
    final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';

    await recorder!.startRecorder(toFile: path);

    setState(() {
      isRecording = true;
      audioPath = path;
    });

    print("🎤 Recording path: $path");
  }
  Future<void> playAudio() async {

    if (audioPath == null) return;

    if (isPlaying) {
      await player.stop();
      setState(() => isPlaying = false);
    } else {
      await player.play(DeviceFileSource(audioPath!));
      setState(() => isPlaying = true);
    }
  }

  Future<void> stopRecording() async {
    await recorder!.stopRecorder();

    setState(() {
      isRecording = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم تسجيل الصوت 🎤")),
    );
  }

  Future<void> pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        selectedImage = File(file.path);
      });
    }
  }

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => startDate = picked);
    }
  }

  Future<void> pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => endDate = picked);
    }
  }

  Future<void> pickTime() async {
    final picked =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  Future<void> createReminder() async {

    if (medicineNameController.text.trim().isEmpty ||
        startDate == null ||
        endDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("اكمل جميع البيانات")),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("المستخدم غير مسجل دخول");

      final reminderDateTime = DateTime(
        startDate!.year,
        startDate!.month,
        startDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      /// ✅ رفع الصورة فقط إذا المستخدم اختار صورة جديدة
      if (selectedImage != null) {
        final uploaded = await CloudinaryService.uploadImage(selectedImage!);
        if (uploaded != null) {
          imageUrl = uploaded;
        }
      }
      /// 🔍 تأكيد الصوت قبل الرفع
      if (audioPath != null) {
        print("📂 Audio path: $audioPath");
        print("📂 Exists: ${File(audioPath!).existsSync()}");
      }

      /// 🔊 رفع الصوت
      if (audioPath != null) {

        final file = File(audioPath!);

        if (file.existsSync()) {

          print("🚀 جاري رفع الصوت...");

          final uploaded = await CloudinaryService.uploadAudio(file);

          if (uploaded != null) {
            audioUrl = uploaded;
            print("✅ تم رفع الصوت: $audioUrl");
          } else {
            print("❌ فشل رفع الصوت");
          }

        } else {
          print("❌ الملف غير موجود");
        }
      }
      /// ✅ حماية من null
      final safeImageUrl = imageUrl ?? "";
      final safeAudioUrl = audioUrl ?? "";

      /// ✅ البيانات
      final data = {
        "medicineName": medicineNameController.text.trim(),
        "startDate": Timestamp.fromDate(startDate!),
        "endDate": Timestamp.fromDate(endDate!),
        "time": Timestamp.fromDate(reminderDateTime),
        "doseAmount": doseAmount,
        "doseUnit": doseUnit,
        "afterMeal": afterMeal,
        "imageUrl": safeImageUrl,
        "audioUrl": safeAudioUrl,
      };

      if (widget.docId != null) {
        // ✏️ تعديل
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(widget.docId)
            .update(data);

        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("watch_data")
            .doc("next_med")
            .set({
          "name": medicineNameController.text.trim(),
          "time": Timestamp.fromDate(reminderDateTime),
          "audioUrl": safeAudioUrl,
          "imageUrl": safeImageUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم تعديل التذكير")),
        );

      } else {
        // ➕ إنشاء
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .add({
          ...data,
          "createdAt": FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم إنشاء التذكير")),
        );
      }

      if (!mounted) return;

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("خطأ: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "إنشاء تذكير",
            style: TextStyle(color: Colors.black),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text("معلومات الدواء",
                            style: TextStyle(fontWeight: FontWeight.bold)),

                        const SizedBox(height: 16),

                        greyBox(
                          child: TextField(
                            controller: medicineNameController,
                            decoration: const InputDecoration(
                              hintText: "ادخل اسم الدواء",
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        greyBox(
                          onTap: pickImage,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedImage != null
                                        ? "تم اختيار صورة"
                                        : "التقط صورة للدواء",
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "صورة الدواء تساعد على التذكر",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(Icons.image_outlined),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        greyBox(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isRecording
                                        ? "جاري التسجيل..."
                                        : audioPath != null
                                        ? "تم تسجيل صوت"
                                        : "تسجيل صوتي",
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "الصوت يساعد على التذكر",
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),

                              Row(
                                children: [

                                  /// 🎤 تسجيل
                                  IconButton(
                                    icon: Icon(
                                      isRecording ? Icons.stop : Icons.mic,
                                      color: isRecording ? Colors.red : Colors.black,
                                    ),
                                    onPressed: () async {
                                      if (isRecording) {
                                        await stopRecording();
                                      } else {
                                        await startRecording();
                                      }
                                    },
                                  ),

                                  /// ▶️ تشغيل
                                  if (audioPath != null)
                                    IconButton(
                                      icon: Icon(
                                        isPlaying ? Icons.stop : Icons.play_arrow,
                                        color: isPlaying ? Colors.red : Colors.black,
                                      ),
                                      onPressed: playAudio,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),



                        const SizedBox(height: 18),

                        /// 📅 التاريخ
                        Row(
                          children: [
                            Expanded(
                              child: greyBox(
                                onTap: pickStartDate,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(startDate == null
                                        ? "تاريخ البداية"
                                        : "${startDate!.day}/${startDate!.month}/${startDate!.year}"),
                                    const Icon(Icons.calendar_today_outlined),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: greyBox(
                                onTap: pickEndDate,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(endDate == null
                                        ? "تاريخ النهاية"
                                        : "${endDate!.day}/${endDate!.month}/${endDate!.year}"),
                                    const Icon(Icons.calendar_today_outlined),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        /// ⏰ الوقت
                        greyBox(
                          onTap: pickTime,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedTime == null
                                    ? "اختاري الوقت"
                                    : selectedTime!.format(context),
                              ),
                              const Icon(Icons.access_time),
                            ],
                          ),
                        ),



                        const SizedBox(height: 28),

                        Row(
                          children: [
                            Expanded(
                              child: greyBox(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          if (doseAmount > 1) doseAmount--;
                                        });
                                      },
                                      icon: const Icon(Icons.remove),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      iconSize: 20,
                                    ),
                                    Text("$doseAmount $doseUnit"),
                                    const SizedBox(height: 12),

                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          doseAmount++;
                                        });
                                      },
                                      icon: const Icon(Icons.add),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      iconSize: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [

                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    doseUnit = "حبة";
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: doseUnit == "حبة"
                                        ? const Color(0xFF5B2E91)
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(child: Text("حبة")),
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    doseUnit = "شراب";
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: doseUnit == "شراب"
                                        ? const Color(0xFF5B2E91)
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(child: Text("شراب")),
                                ),
                              ),
                            ),

                          ],
                        ),


                        const SizedBox(height: 24),

                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDEDED),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => afterMeal = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: afterMeal
                                          ? const Color(0xFF5B2E91)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "بعد الأكل",
                                        style: TextStyle(
                                          color: afterMeal
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => afterMeal = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: !afterMeal
                                          ? const Color(0xFF5B2E91)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "قبل الأكل",
                                        style: TextStyle(
                                          color: !afterMeal
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : createReminder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B2E91),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                      isLoading
                          ? "جاري الحفظ..."
                          : (widget.docId != null
                          ? "حفظ التعديلات"
                          : "إنشاء التذكير")),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}