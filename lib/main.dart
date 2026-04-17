import 'dart:io'; // ضروري جداً لتجاوز الـ SSL
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'opnsense/screens/opnsense/auth_mobile/motring/security_layer.dart';
import 'opnsense/screens/opnsense/auth_mobile/security_entry_screen.dart';
import 'opnsense/screens/opnsense/auth_mobile/set_initial_pin_screen.dart';
import 'opnsense/services/security_service.dart';

// --- 1. كود تجاوز فحص الشهادة (حل مشكلة CERTIFICATE_VERIFY_FAILED) ---
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

// محرك تغيير الثيم العالمي (ValueNotifier)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  // تفعيل تجاوز الشهادة قبل أي عمليات اتصال
  HttpOverrides.global = MyHttpOverrides();

  // التأكد من جاهزية محرك فلاتر
  WidgetsFlutterBinding.ensureInitialized();

  // تحميل وضع الثيم المحفوظ
  String savedMode = await SecurityService.getThemeMode();
  if (savedMode == 'dark') themeNotifier.value = ThemeMode.dark;
  if (savedMode == 'light') themeNotifier.value = ThemeMode.light;

  // فحص الخزنة المشفرة لمعرفة هل هذا أول دخول أم لا
  const storage = FlutterSecureStorage();
  String? savedPin = await storage.read(key: 'secure_pin');

  runApp(MyApp(isFirstTime: savedPin == null));
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;
  const MyApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SOC System',
          
          themeMode: mode, // استخدام الوضع المختار من قبل المستخدم

          // 1. الثيم الفاتح (Light Mode)
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: Colors.blueGrey,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A1A2E),
              foregroundColor: Colors.white,
            ),
          ),

          // 2. الثيم الداكن (Dark Mode)
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: Colors.blueGrey,
            scaffoldBackgroundColor: const Color(0xFF0D1117),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF161B22),
              foregroundColor: Colors.white,
            ),
          ),

          home: SecurityWrapper(
            child: isFirstTime
                ? const SetInitialPinScreen()
                : const SecurityEntryScreen(),
          ),
        );
      },
    );
  }
}