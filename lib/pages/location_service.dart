import 'package:geolocator/geolocator.dart';

class LocationService {

  static Future<Position?> getLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      /// 🔥 أهم حل: timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception("Location timeout");
        },
      );

    } catch (e) {
      return null;
    }
  }
}