import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:soc/opnsense/screens/wazuh/indexer/wazuh_alerts_screen.dart';
// ملاحظة: تأكد من إنشاء هذا الملف أو تغييره للمسار الصحيح لديك

class WazuhIndexerLoginScreen extends StatefulWidget {
  const WazuhIndexerLoginScreen({super.key});

  @override
  State<WazuhIndexerLoginScreen> createState() => _WazuhIndexerLoginScreenState();
}

class _WazuhIndexerLoginScreenState extends State<WazuhIndexerLoginScreen> {
  // وحدات التحكم في النصوص
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _userController = TextEditingController(text: "admin");
  final TextEditingController _passController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // دالة تسجيل الدخول والتحقق من المنفذ 9200
  Future<void> _connectToIndexer() async {
    print("--- محاولة بدء الاتصال ---"); // سيظهر في الـ Logs
    setState(() => _isLoading = true);

    try {
      final String ip = _ipController.text.trim();
      String basicAuth = 'Basic ' + base64Encode(utf8.encode('${_userController.text}:${_passController.text}'));

      print("جاري الاتصال بـ: https://$ip:9200/");

      final response = await http.get(
        Uri.parse("https://$ip:9200/"),
        headers: {'Authorization': basicAuth},
      ).timeout(const Duration(seconds: 10));

      print("كود الاستجابة: ${response.statusCode}");
      print("محتوى الاستجابة: ${response.body}");

      if (response.statusCode == 200) {
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => WazuhAlertsScreen(serverIp: ip, authHeader: basicAuth)
        ));
      } else {
        _showSnackBar("فشل: ${response.statusCode}", Colors.red);
      }
    } catch (e) {
      print("خطأ فادح أثناء الاتصال: $e");
      _showSnackBar("فشل الاتصال: تأكد من الـ IP والشبكة", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // خلفية داكنة جداً
      appBar: AppBar(
        title: const Text("INDEXER LOGIN (9200)",
            style: TextStyle(fontSize: 14, letterSpacing: 2, color: Colors.orangeAccent)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة رادار تدل على مراقبة الهجمات
              const Icon(Icons.radar_rounded, size: 80, color: Colors.orangeAccent),
              const SizedBox(height: 20),
              const Text(
                "SECURITY ALERTS HUB",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                "اتصال مباشر بقاعدة بيانات التنبيهات",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 40),

              // حقل IP السيرفر
              _buildInputField(
                controller: _ipController,
                hint: "Server IP (e.g. 192.168.1.100)",
                icon: Icons.dns_outlined,
              ),
              const SizedBox(height: 20),

              // حقل اسم المستخدم
              _buildInputField(
                controller: _userController,
                hint: "Username (admin)",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),

              // حقل كلمة المرور
              _buildInputField(
                controller: _passController,
                hint: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 40),

              // زر تسجيل الدخول
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 8,
                  ),
                  onPressed: _isLoading ? null : _connectToIndexer,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "CONNECT TO LIVE FEED",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "ملاحظة: تأكد من أن منفذ 9200 مفتوح في جدار الحماية",
                style: TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ودجت مخصص لبناء حقول الإدخال
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30),
          prefixIcon: Icon(icon, color: Colors.orangeAccent),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}