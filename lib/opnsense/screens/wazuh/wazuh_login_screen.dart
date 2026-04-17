import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/wazuh_service.dart';
import 'wazuh_dashboard_screen.dart';

class WazuhLoginScreen extends StatefulWidget {
  const WazuhLoginScreen({super.key});

  @override
  State<WazuhLoginScreen> createState() => _WazuhLoginScreenState();
}

class _WazuhLoginScreenState extends State<WazuhLoginScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _handleConnect() async {
    String url = _urlController.text.trim(); // مثال: https://192.168.1.100:55000
    String user = _userController.text.trim();
    String pass = _passController.text.trim();

    if (url.isEmpty || user.isEmpty || pass.isEmpty) {
      _showSnackBar("الرجاء تعبئة جميع الحقول", Colors.orange);
      return;
    }

    // تصحيح الرابط تلقائياً إذا نسى المستخدم http
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }

    setState(() => _isLoading = true);

    try {
      bool success = await WazuhService.login(url, user, pass);

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('wazuh_url', url);
        await prefs.setString('wazuh_user', user);

        _showSnackBar("تم الاتصال بـ Wazuh بنجاح", Colors.blue);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WazuhDashboardScreen()),
        );
      } else {
        _showSnackBar("فشل الاتصال: تأكد من الرابط أو بيانات الـ API", Colors.red);
      }
    } catch (e) {
      _showSnackBar("خطأ غير متوقع: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("ربط سيرفر Wazuh Manager"),
        backgroundColor: Colors.blue[900],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Icon(Icons.security_update_good, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 30),

            // حقل الرابط (يدعم http و https)
            _buildInput(_urlController, "رابط السيرفر مع المنفذ (192.168.1.1:55000)", Icons.link),
            const SizedBox(height: 15),
            _buildInput(_userController, "اسم مستخدم الـ API", Icons.person_outline),
            const SizedBox(height: 15),
            _buildInput(_passController, "كلمة المرور", Icons.lock_clock_outlined, isPass: true),

            const SizedBox(height: 40),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.blueAccent)
                : SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleConnect,
                child: const Text("اختبار وحفظ الاتصال", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, {bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}