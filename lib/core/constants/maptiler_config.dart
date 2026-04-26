/// MapTiler API Configuration
class MapTilerConfig {
  static const String apiKey = '4dyHtxDFaDz02KChDs4I';
  static const String tileUrl =
      'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$apiKey';
  static const String searchUrl = 'https://api.maptiler.com/geocoding';

  // Default map center (can be updated to your region)
  static const double defaultLatitude = 40.7128; // New York
  static const double defaultLongitude = -74.0060;
  static const double defaultZoom = 13.0;
}
