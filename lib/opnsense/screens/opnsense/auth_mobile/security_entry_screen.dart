import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:soc/opnsense/home_screen.dart';
import '../../../services/security_service.dart';

class SecurityEntryScreen extends StatefulWidget {
  // هذا البرامتر ضروري لكي يعمل الـ SecurityWrapper بدون أخطاء
  final VoidCallback? onAuthenticated;

  const SecurityEntryScreen({super.key, this.onAuthenticated});

  @override
  State<SecurityEntryScreen> createState() => _SecurityEntryScreenState();
}

class _SecurityEntryScreenState extends State<SecurityEntryScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  final TextEditingController _passwordController = TextEditingController();
  bool _canCheckBiometrics = false;
  bool _isAuthenticating = false; // لمنع التداخل (authInProgress)
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _initSecurityCheck();
  }

  Future<void> _initSecurityCheck() async {
    bool isSupported = await _auth.isDeviceSupported() || await _auth.canCheckBiometrics;
    bool isUserEnabled = await SecurityService.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _canCheckBiometrics = isSupported && isUserEnabled;
      });
    }

    // إذا كانت البصمة مفعلة، نطلبها فوراً لتسهيل الدخول
    if (_canCheckBiometrics) {
      _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;
    
    setState(() => _isAuthenticating = true);
    try {
      final bool didAuth = await _auth.authenticate(
        localizedReason: 'الرجاء التحقق للوصول إلى نظام SOC',
      );

      if (didAuth) {
        _accessGranted();
      }
    } catch (e) {
      debugPrint("خطأ في البصمة: $e");
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void _verifyManualPassword() async {
    // نستخدم verifyPIN لكنها الآن تقارن نصوصاً وليس أرقاماً فقط
    bool isValid = await SecurityService.verifyPIN(_passwordController.text);
    if (isValid) {
      _accessGranted();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("كلمة المرور غير صحيحة!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      _passwordController.clear();
    }
  }

  void _accessGranted() {
    if (widget.onAuthenticated != null) {
      // إغلاق طبقة الحماية (SecurityWrapper)
      widget.onAuthenticated!();
    } else {
      // الانتقال للهوم سكرين في حالة الدخول الأول
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (c) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على ألوان الثيم الحالي
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 100, color: Colors.blueAccent),
              const SizedBox(height: 20),
              Text(
                "نظام SOC مؤمن",
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : Colors.black87
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "أدخل كلمة المرور للمتابعة", 
                style: TextStyle(color: isDark ? Colors.grey : Colors.black54)
              ),
              const SizedBox(height: 40),

              // حقل إدخال كلمة المرور (نصي وليس رقمي)
              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                keyboardType: TextInputType.text, 
                style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: isDark ? BorderSide.none : const BorderSide(color: Colors.blueAccent),
                  ),
                  hintText: "كلمة المرور",
                  hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
                  prefixIcon: const Icon(Icons.lock_open, color: Colors.blueAccent),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _verifyManualPassword,
                  child: const Text("تسجيل الدخول", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),

              if (_canCheckBiometrics) ...[
                const SizedBox(height: 30),
                const Text("أو استخدم المصادقة الحيوية", style: TextStyle(color: Colors.grey)),
                IconButton(
                  icon: const Icon(Icons.fingerprint, size: 70, color: Colors.blue),
                  onPressed: _authenticateWithBiometrics,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}