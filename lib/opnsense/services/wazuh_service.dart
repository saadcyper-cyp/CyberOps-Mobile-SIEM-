import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;

class WazuhService {
  // متغيرات ثابتة لحفظ البيانات بعد تسجيل الدخول بنجاح
  static String? _token;
  static String? _baseUrl;

  // دالة لإنشاء عميل HTTP يتجاهل أخطاء الشهادات (SSL)
  static http.Client _getUnsafeClient() {
    final ioc = HttpClient();
    ioc.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(ioc);
  }

  // 1. دالة تسجيل الدخول (Login)
  static Future<bool> login(String url, String user, String pass) async {
    try {
      // تنظيف الرابط وحفظه في المتغير العام لاستخدامه في الدوال الأخرى
      _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;

      final uri = Uri.parse("$_baseUrl/security/user/authenticate");
      String basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';

      final client = _getUnsafeClient();

      final response = await client.get(
        uri,
        headers: {
          'Authorization': basicAuth,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['data']['token']; // حفظ التوكن
        return true;
      }
      return false;
    } catch (e) {
      print("Wazuh Login Error: $e");
      return false;
    }
  }

  // 2. دالة جلب الأجهزة (Agents) - تستخدم الآن _baseUrl و _token المحفوظين
  static Future<List<dynamic>> getAgents() async {
    // التأكد من أننا سجلنا الدخول أولاً
    if (_token == null || _baseUrl == null) {
      print("خطأ: لم يتم تسجيل الدخول بعد.");
      return [];
    }

    try {
      final uri = Uri.parse("$_baseUrl/agents");
      final client = _getUnsafeClient();

      final response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // وازه يعيد الأجهزة داخل قائمة باسم affected_items
        return data['data']['affected_items'] ?? [];
      }
      return [];
    } catch (e) {
      print("Wazuh Fetch Agents Error: $e");
      return [];
    }
  }
  static Future<List<dynamic>> getSecurityAlerts() async {
    if (_token == null || _baseUrl == null) return [];
    try {
      final uri = Uri.parse("$_baseUrl/manager/logs?limit=100&sort=-timestamp");
      final response = await _getUnsafeClient().get(
        uri,
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['affected_items'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  static Future<List<dynamic>> getVulnerabilities(String agentId) async {
    if (_token == null || _baseUrl == null) return [];

    try {
      // مسار جلب الثغرات لجهاز معين
      final uri = Uri.parse("$_baseUrl/vulnerability/$agentId");
      final client = _getUnsafeClient();

      final response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['affected_items'] ?? [];
      }
      return [];
    } catch (e) {
      print("Vulnerability Fetch Error: $e");
      return [];
    }
  }
}