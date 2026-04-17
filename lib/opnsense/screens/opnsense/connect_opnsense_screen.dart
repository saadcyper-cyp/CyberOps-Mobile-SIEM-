import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// استيراد الخدمة باستخدام المسار النسبي
import '../../services/opnsense_service.dart';
// استيراد الداشبورد للانتقال إليه (سنقوم بإنشائه في الخطوة التالية)
import 'opnsense_dashboard_screen.dart';

class OPNsenseLoginScreen extends StatefulWidget {
  const OPNsenseLoginScreen({super.key});

  @override
  State<OPNsenseLoginScreen> createState() => _OPNsenseLoginScreenState();
}

class _OPNsenseLoginScreenState extends State<OPNsenseLoginScreen> {
  // تعريف الخدمة التي أنشأناها
  final OPNsenseService _apiService = OPNsenseService();

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _secretController = TextEditingController();

  bool _isLoading = false;

  // دالة مساعدة لإظهار رسائل للمستخدم
  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // الدالة الأساسية للربط
  Future<void> _handleConnect() async {
    String ip = _ipController.text.trim();
    String key = _keyController.text.trim();
    String secret = _secretController.text.trim();

    if (ip.isEmpty || key.isEmpty || secret.isEmpty) {
      _showSnackBar("الرجاء تعبئة جميع الحقول", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // استخدام الخدمة لاختبار البيانات
      bool success = await _apiService.testConnection(ip, key, secret);

      if (success) {
        // حفظ البيانات في الذاكرة المحلية للجهاز
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('opnsense_ip', ip);
        await prefs.setString('opnsense_key', key);
        await prefs.setString('opnsense_secret', secret);

        _showSnackBar("تم الاتصال بنجاح", Colors.green);

        if (!mounted) return;
        // الانتقال لصفحة الداشبورد وحذف صفحة الدخول من الذاكرة
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OPNsenseDashboardScreen()),
        );
      } else {
        _showSnackBar("فشل الاتصال: تأكد من الرابط والمفاتيح والصلاحيات", Colors.red);
      }
    } catch (e) {
      _showSnackBar("خطأ في الشبكة: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ربط نظام OPNsense"),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.hub_outlined, size: 70, color: Colors.red),
            const SizedBox(height: 20),
            const Text("أدخل بيانات API الخاصة بمركز العمليات SOC"),
            const SizedBox(height: 30),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: "رابط السيرفر (https://1.1.1.1)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: "API Key",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _secretController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "API Secret",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
                onPressed: _handleConnect,
                child: const Text("اختبار وحفظ الاتصال", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}