import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'firebase_service.dart';

class SafeZonePage extends StatefulWidget {
  const SafeZonePage({super.key});

  @override
  State<SafeZonePage> createState() => _SafeZonePageState();
}

class _SafeZonePageState extends State<SafeZonePage> {

  LatLng selectedLocation = const LatLng(25.3833, 49.5861);

  double radius = 200;

  Set<Circle> circles = {};
  Set<Marker> markers = {};

  List<LatLng> zones = [];
  List<String> zoneNames = [];

  /// 🔥 مؤقت للتحديد
  LatLng? tempLocation;

  @override
  void initState() {
    super.initState();
    loadSafeZones();
  }

  /////////////////////////////////////////////////////////
  Future<void> loadSafeZones() async {

    final data = await FirebaseService.getSafeZonesList();

    zones.clear();
    zoneNames.clear();
    circles.clear();
    markers.clear();

    for (int i = 0; i < data.length; i++) {

      final zone = data[i];

      final position = LatLng(zone["lat"], zone["lng"]);
      final name = zone["name"] ?? "منطقة";

      zones.add(position);
      zoneNames.add(name);

      circles.add(
        Circle(
          circleId: CircleId("zone_$i"),
          center: position,
          radius: (zone["radius"] ?? 200).toDouble(),
          fillColor: const Color(0xFF7B1FA2).withOpacity(0.3),
          strokeColor: const Color(0xFF7B1FA2),
          strokeWidth: 3,
        ),
      );

      markers.add(
        Marker(
          markerId: MarkerId("zone_$i"),
          position: position,
          infoWindow: InfoWindow(title: name),
          draggable: true,
          onDragEnd: (newPos) {
            zones[i] = newPos;

            circles.removeWhere((c) => c.circleId.value == "zone_$i");

            circles.add(
              Circle(
                circleId: CircleId("zone_$i"),
                center: newPos,
                radius: radius,
                fillColor: const Color(0xFF7B1FA2).withOpacity(0.3),
                strokeColor: const Color(0xFF7B1FA2),
                strokeWidth: 3,
              ),
            );

            setState(() {});
          },
        ),
      );
    }

    setState(() {});
  }

  /////////////////////////////////////////////////////////
  void _addZone(LatLng position) {

    TextEditingController controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Text("اسم المنطقة"),

                TextField(controller: controller),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () {

                    final name = controller.text.trim();
                    if (name.isEmpty) return;

                    final index = zones.length;

                    zones.add(position);
                    zoneNames.add(name);

                    /// 🔥 احذف المؤقت
                    circles.removeWhere((c) => c.circleId.value == "temp");

                    /// 🔥 الدائرة الحقيقية
                    circles.add(
                      Circle(
                        circleId: CircleId("zone_$index"),
                        center: position,
                        radius: radius,
                        fillColor: const Color(0xFF7B1FA2).withOpacity(0.3),
                        strokeColor: const Color(0xFF7B1FA2),
                        strokeWidth: 3,
                      ),
                    );

                    markers.add(
                      Marker(
                        markerId: MarkerId("zone_$index"),
                        position: position,
                        infoWindow: InfoWindow(title: name),
                        draggable: true,
                        onDragEnd: (newPos) {
                          zones[index] = newPos;
                        },
                      ),
                    );

                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text("إضافة"),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  /////////////////////////////////////////////////////////
  Future<void> saveSafeZone() async {

    await FirebaseService.saveSafeZonesList(
      zones: List.generate(zones.length, (i) => {
        "lat": zones[i].latitude,
        "lng": zones[i].longitude,
        "radius": radius,
        "name": zoneNames[i],
      }),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم الحفظ ⌚")),
    );

    Navigator.pop(context);
  }

  /////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(

        appBar: AppBar(
          title: const Text("المنطقة الآمنة"),
        ),

        body: Column(
          children: [

            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: selectedLocation,
                  zoom: 14,
                ),

                markers: markers,
                circles: circles,

                /// 🔥 أهم تعديل
                onTap: (position) {

                  tempLocation = position;

                  /// 🔥 دائرة مباشرة
                  circles.removeWhere((c) => c.circleId.value == "temp");

                  circles.add(
                    Circle(
                      circleId: const CircleId("temp"),
                      center: position,
                      radius: radius,
                      fillColor:
                      const Color(0xFF7B1FA2).withOpacity(0.3),
                      strokeColor: const Color(0xFF7B1FA2),
                      strokeWidth: 3,
                    ),
                  );

                  setState(() {});

                  _addZone(position);
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  const Text("نطاق المنطقة"),

                  Slider(
                    value: radius,
                    min: 50,
                    max: 1000,
                    onChanged: (value) {
                      setState(() {
                        radius = value;

                        /// 🔥 تحديث الدائرة المؤقتة
                        if (tempLocation != null) {
                          circles.removeWhere(
                                  (c) => c.circleId.value == "temp");

                          circles.add(
                            Circle(
                              circleId: const CircleId("temp"),
                              center: tempLocation!,
                              radius: radius,
                              fillColor: const Color(0xFF7B1FA2)
                                  .withOpacity(0.3),
                              strokeColor: const Color(0xFF7B1FA2),
                              strokeWidth: 3,
                            ),
                          );
                        }
                      });
                    },
                  ),

                  ElevatedButton(
                    onPressed: saveSafeZone,
                    child: const Text("حفظ"),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}