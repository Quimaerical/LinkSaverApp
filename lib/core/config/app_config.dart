class AppConfig {
  AppConfig._();

  static const String appName = 'LinkSaver';
  static const String appVersion = '1.0.0';

  // Obfuscated default URL using XOR key 0x5A (90)
  // Decodes to "http://127.0.0.1:8080"
  static const int _xorKey = 0x5A;
  static const List<int> _defaultObfuscatedUrl = [
    50, 46, 46, 42, 96, 117, 117, 107, 104, 109, 116, 106, 116, 106, 116, 107, 96, 98, 106, 98, 106
  ];

  static String get defaultBaseUrl {
    const overrideUrl = String.fromEnvironment('API_BASE_URL');
    if (overrideUrl.isNotEmpty) {
      return overrideUrl;
    }
    return decodeUrl(_defaultObfuscatedUrl, _xorKey);
  }

  static String decodeUrl(List<int> codes, int key) {
    return String.fromCharCodes(codes.map((c) => c ^ key));
  }

  static const String clientType = 'Android';
}
