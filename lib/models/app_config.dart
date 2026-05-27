class AppConfig {
  const AppConfig({
    required this.serverUrl,
    required this.token,
    required this.deviceName,
  });

  final String serverUrl;
  final String token;
  final String deviceName;

  bool get isComplete =>
      serverUrl.trim().isNotEmpty &&
      token.trim().isNotEmpty &&
      deviceName.trim().isNotEmpty;

  AppConfig copyWith({String? serverUrl, String? token, String? deviceName}) {
    return AppConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      token: token ?? this.token,
      deviceName: deviceName ?? this.deviceName,
    );
  }
}
