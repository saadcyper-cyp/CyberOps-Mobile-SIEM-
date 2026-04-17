import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/thehive_case.dart';

class TheHiveService {
  final String baseUrl;
  final String apiKey;

  TheHiveService({required this.baseUrl, required this.apiKey});

  Future<List<TheHiveCase>> getCases() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/case'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('TheHive Response Status: ${response.statusCode}');
      print('TheHive Response Content-Type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') ?? false) {
          List<dynamic> data = jsonDecode(response.body);
          return data.map((item) => TheHiveCase.fromJson(item)).toList();
        } else {
          print('TheHive Response Body (Unexpected): ${response.body}');
          throw Exception('استلمنا HTML بدلاً من JSON. تأكد من صحة الرابط (URL).');
        }
      } else {
        throw Exception('فشل جلب القضايا: كود ${response.statusCode}');
      }
    } catch (e) {
      print('TheHive Service Error: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/status'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('TheHive Test Status: ${response.statusCode}');
      return response.statusCode == 200 && (response.headers['content-type']?.contains('application/json') ?? false);
    } catch (e) {
      print('TheHive Test Error: $e');
      return false;
    }
  }
}
