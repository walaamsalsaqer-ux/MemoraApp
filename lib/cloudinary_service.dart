import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class CloudinaryService {

  static const cloudName = "diikvvci5";
  static const uploadPreset = "memora_upload";

  /// 🖼️ رفع صورة
  static Future<String?> uploadImage(File file) async {

    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    request.fields['upload_preset'] = uploadPreset;

    final response = await request.send();

    print("📸 Image STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      final res = await response.stream.bytesToString();
      final data = jsonDecode(res);

      print("✅ Image uploaded: ${data['secure_url']}");

      return data['secure_url'];
    } else {
      final res = await response.stream.bytesToString();
      print("❌ Image upload failed: ${response.statusCode}");
      print("❌ Response: $res");
      return null;
    }
  }

  /// 🔊 رفع صوت (بدون تحويل MP3)
  static Future<String?> uploadAudio(File file) async {

    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/video/upload",
    );

    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    request.fields['upload_preset'] = uploadPreset;

    final response = await request.send();

    print("🎤 Audio STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      final res = await response.stream.bytesToString();
      final data = jsonDecode(res);

      final url = data['secure_url'];

      print("✅ Audio uploaded: $url");

      return url; // 🔥 يرجع الرابط مباشرة
    } else {
      final res = await response.stream.bytesToString();
      print("❌ Audio upload failed: ${response.statusCode}");
      print("❌ Response: $res");
      return null;
    }
  }
}