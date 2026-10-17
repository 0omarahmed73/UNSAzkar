import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

/// Reverse-geocodes to a short Arabic-friendly label, or null offline.

/// A manually selectable city (offline, no network needed).
class PrayerCity {
  const PrayerCity({required this.label, required this.lat, required this.lng});

  final String label;
  final double lat;
  final double lng;
}

/// Curated major cities with verified coordinates. Shown as-is; the user
/// picks explicitly — never silently assumed.
const List<PrayerCity> manualCities = [
  PrayerCity(label: 'القاهرة، مصر', lat: 30.0444, lng: 31.2357),
  PrayerCity(label: 'الجيزة، مصر', lat: 30.0131, lng: 31.2089),
  PrayerCity(label: 'الإسكندرية، مصر', lat: 31.2001, lng: 29.9187),
  PrayerCity(label: 'مكة المكرمة، السعودية', lat: 21.4225, lng: 39.8262),
  PrayerCity(label: 'المدينة المنورة، السعودية', lat: 24.5247, lng: 39.5692),
  PrayerCity(label: 'الرياض، السعودية', lat: 24.7136, lng: 46.6753),
  PrayerCity(label: 'دبي، الإمارات', lat: 25.2048, lng: 55.2708),
  PrayerCity(label: 'عمّان، الأردن', lat: 31.9539, lng: 35.9106),
  PrayerCity(label: 'القدس، فلسطين', lat: 31.7683, lng: 35.2137),
  PrayerCity(label: 'بغداد، العراق', lat: 33.3152, lng: 44.3661),
  PrayerCity(label: 'الخرطوم، السودان', lat: 15.5007, lng: 32.5599),
  PrayerCity(label: 'الدار البيضاء، المغرب', lat: 33.5731, lng: -7.5899),
  PrayerCity(label: 'إسطنبول، تركيا', lat: 41.0082, lng: 28.9784),
  PrayerCity(label: 'كراتشي، باكستان', lat: 24.8607, lng: 67.0011),
  PrayerCity(label: 'كوالالمبور، ماليزيا', lat: 3.1390, lng: 101.6869),
  PrayerCity(label: 'جاكرتا، إندونيسيا', lat: -6.2088, lng: 106.8456),
];

enum LocationStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  unavailable,
}

extension LocationStatusLabel on LocationStatus {
  String get arabic => switch (this) {
        LocationStatus.granted => 'تم تحديد الموقع',
        LocationStatus.denied => 'تم رفض إذن الموقع',
        LocationStatus.deniedForever =>
          'إذن الموقع مرفوض دائمًا — فعّله من إعدادات النظام',
        LocationStatus.serviceDisabled => 'خدمة الموقع متوقفة على الجهاز',
        LocationStatus.unavailable => 'تعذر تحديد الموقع',
      };
}

class LocatedPosition {
  const LocatedPosition(
      {required this.lat, required this.lng, required this.label});

  final double lat;
  final double lng;
  final String label;
}

/// Device location via geolocator, requested only when the user asks.
/// Never called at startup; every failure maps to an explainable status.
class LocationService {
  Future<(LocationStatus, LocatedPosition?)> requestDeviceLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return (LocationStatus.serviceDisabled, null);
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return (LocationStatus.denied, null);
      }
      if (permission == LocationPermission.deniedForever) {
        return (LocationStatus.deniedForever, null);
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);
      String label = 'موقعي الحالي';
      try {
        final places = await geo.Geocoding()
            .placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (places.isNotEmpty) {
          final p = places.first;
          final parts = [p.locality, p.country]
              .where((s) => s != null && s.isNotEmpty)
              .join('، ');
          if (parts.isNotEmpty) label = parts;
        }
      } catch (_) {
        // Offline or geocoding unavailable — keep the generic label.
      }
      return (
        LocationStatus.granted,
        LocatedPosition(lat: pos.latitude, lng: pos.longitude, label: label)
      );
    } catch (_) {
      return (LocationStatus.unavailable, null);
    }
  }

  /// Reverse-geocodes to a short label, or null when offline/unavailable.
  Future<String?> describe(double lat, double lng) async {
    try {
      final places = await geo.Geocoding().placemarkFromCoordinates(lat, lng);
      if (places.isEmpty) return null;
      final p = places.first;
      final parts = [p.locality, p.country]
          .where((s) => s != null && (s as String).isNotEmpty)
          .toList();
      if (parts.isEmpty) return null;
      return parts.join('، ');
    } catch (_) {
      return null;
    }
  }
}
