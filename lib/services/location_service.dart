import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<bool> requestPermission() async {
    var status = await Permission.location.status;
    if (status.isGranted) return true;
    if (status.isDenied) {
      status = await Permission.location.request();
      return status.isGranted;
    }
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }

  static Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception("Gagal mendapatkan lokasi (timeout)"),
    );
  }

  static Future<Placemark?> getPlacemark(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      return placemarks.isNotEmpty ? placemarks.first : null;
    } catch (_) {
      return null;
    }
  }

  static String formatLocation(Placemark? place) {
    if (place == null) return "Lokasi tidak diketahui";
    return "${place.subAdministrativeArea ?? ''}, ${place.locality ?? ''}"
        .trim()
        .replaceAll(RegExp(r'^,\s*|\s*,\s*$'), '');
  }
}
