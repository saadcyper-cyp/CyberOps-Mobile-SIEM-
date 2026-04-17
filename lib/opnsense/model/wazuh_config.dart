class WazuhConfig {
  String ip;
  String port;
  String username;
  String password;

  WazuhConfig({
    required this.ip,
    this.port = "55000", // المنفذ الافتراضي لـ Wazuh API
    required this.username,
    required this.password
  });

  String get apiUrl => "https://$ip:$port";
}