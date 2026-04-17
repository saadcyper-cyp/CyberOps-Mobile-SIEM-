import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart'; // نحتاجها لإظهار نافذة إدخال الرمز

class SecurityService {
  static const _storage = FlutterSecureStorage();

  // --- دوالك الأصلية (لا تلمسها لضمان عمل الصفحات الأخرى) ---
  static String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static Future<void> saveSecurePIN(String pin) async {
    String hashedPin = _hashPassword(pin);
    await _storage.write(key: 'secure_pin', value: hashedPin);
  }

  static Future<bool> verifyPIN(String inputPin) async {
    String? savedHash = await _storage.read(key: 'secure_pin');
    if (savedHash == null) return false;
    return savedHash == _hashPassword(inputPin);
  }

  static Future<void> setBiometricEnabled(bool status) async {
    await _storage.write(key: 'bio_enabled', value: status.toString());
  }

  static Future<bool> isBiometricEnabled() async {
    String? status = await _storage.read(key: 'bio_enabled');
    return status == 'true';
  }

  // --- إدارة وضع الثيم (الليل والنهار) ---
  static Future<void> setThemeMode(String mode) async {
    await _storage.write(key: 'theme_mode', value: mode);
  }

  static Future<String> getThemeMode() async {
    return await _storage.read(key: 'theme_mode') ?? 'system';
  }

  // --- الإضافة الجديدة لزر الحظر (تستخدم دوالك الأصلية بالداخل) ---
  static Future<bool> authenticate(BuildContext context) async {
    String? savedPinHash = await _storage.read(key: 'secure_pin');

    if (savedPinHash == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("يرجى إعداد رمز PIN في الإعدادات أولاً"))
      );
      return false;
    }

    // إظهار نافذة تطلب الـ PIN
    String? inputPin = await _showPinInputDialog(context);

    if (inputPin != null) {
      // نستخدم دالتك الأصلية verifyPIN للتحقق
      return await verifyPIN(inputPin);
    }
    return false;
  }

  // واجهة إدخال الرمز بستايل يتناسب مع مشروعك
  static Future<String?> _showPinInputDialog(BuildContext context) async {
    TextEditingController pinController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D14),
        title: const Text("تأكيد إجراء الحظر", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Color(0xFF00FFCC)),
          decoration: const InputDecoration(
            labelText: "أدخل رمز PIN الخاص بالتطبيق",
            labelStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          TextButton(
            onPressed: () => Navigator.pop(context, pinController.text),
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );
  }
}