import 'package:flutter/material.dart';
import 'package:soc/opnsense/home_screen.dart';

import '../../../services/security_service.dart';

//import 'opnsense/screens/connect_opnsense_screen.dart'; // تأكد من المسار الصحيح لهوم سكرين

class SetInitialPinScreen extends StatefulWidget {
  const SetInitialPinScreen({super.key});

  @override
  State<SetInitialPinScreen> createState() => _SetInitialPinScreenState();
}

class _SetInitialPinScreenState extends State<SetInitialPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  void _saveAndProceed() async {
    if (_pinController.text.length >= 4 && _pinController.text == _confirmController.text) {
      // حفظ الرمز مشفراً في الخزنة
      await SecurityService.saveSecurePIN(_pinController.text);
      // تفعيل البصمة افتراضياً
      await SecurityService.setBiometricEnabled(true);

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تأكد من تطابق الرمزين (4 أرقام على الأقل)"), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      // أضفنا هذا السطر لمنع لوحة المفاتيح من دفع العناصر بشكل خاطئ
      resizeToAvoidBottomInset: true,
      body: Center( // وضع المحتوى في المنتصف
        child: SingleChildScrollView( // الحل السحري لمشكلة الـ Overflow
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // لجعل العمود يأخذ أقل مساحة ممكنة
            children: [
              const Icon(Icons.admin_panel_settings, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                "إعداد الوصول الأمني",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                "أنت تقوم بتشغيل نظام SOC لأول مرة، يرجى تعيين رمز PIN",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // حقل الرمز الأول
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.text, // تم التغيير من number لـ text ليتوافق مع شاشة الدخول
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "كلمة المرور الجديدة",
                  labelStyle: TextStyle(color: Colors.blue),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
              ),
              const SizedBox(height: 15),

              // تأكيد الرمز
              TextField(
                controller: _confirmController,
                obscureText: true,
                keyboardType: TextInputType.text, // تم التغيير من number لـ text
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "تأكيد كلمة المرور",
                  labelStyle: TextStyle(color: Colors.blue),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _saveAndProceed,
                child: const Text(
                  "تفعيل الحماية والدخول",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              // أضفنا مسافة صغيرة في الأسفل لضمان عدم التصاق الزر بحافة الشاشة عند التمرير
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}