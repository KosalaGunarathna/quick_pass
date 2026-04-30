/// MapTiler API Configuration
class MapTilerConfig {
  static const String apiKey = '4dyHtxDFaDz02KChDs4I';
  static const String tileUrl =
      'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$apiKey';
  static const String searchUrl = 'https://api.maptiler.com/geocoding';

  // Default map center - Colombo, Sri Lanka
  static const double defaultLatitude = 6.9271;
  static const double defaultLongitude = 80.6337;
  static const double defaultZoom = 13.0;
}
