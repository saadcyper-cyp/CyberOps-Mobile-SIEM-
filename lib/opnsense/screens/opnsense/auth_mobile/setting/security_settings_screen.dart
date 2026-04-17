import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soc/main.dart'; // نحتاجها للوصول للـ themeNotifier
import 'package:soc/opnsense/services/security_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _isBioEnabled = false;
  String _currentTheme = 'system';

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  // تحميل الإعدادات الحالية من الخزنة المشفرة
  void _loadCurrentSettings() async {
    bool status = await SecurityService.isBiometricEnabled();
    String theme = await SecurityService.getThemeMode();
    setState(() {
      _isBioEnabled = status;
      _currentTheme = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("إعدادات التشفير والأمان"),
        backgroundColor: isDark ? Colors.blueGrey.shade900 : const Color(0xFF1A1A2E),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "المظهر (الليل والنهار)", 
              style: TextStyle(color: isDark ? Colors.blue : Colors.blueAccent, fontWeight: FontWeight.bold)
            ),
          ),

          // خيار التحكم في الثيم
          ListTile(
            leading: Icon(Icons.palette_outlined, color: isDark ? Colors.white : Colors.black87),
            title: Text("وضع المظهر", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            subtitle: Text(_getThemeLabel(_currentTheme), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
            trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.black45),
            onTap: () => _showThemePicker(context),
          ),

          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "المصادقة البيومترية", 
              style: TextStyle(color: isDark ? Colors.blue : Colors.blueAccent, fontWeight: FontWeight.bold)
            ),
          ),

          // خيار تفعيل/تعطيل البصمة
          SwitchListTile(
            secondary: Icon(Icons.fingerprint, color: isDark ? Colors.white : Colors.black87),
            title: Text("استخدام بصمة الإصبع", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            subtitle: Text("تفعيل الدخول السريع عبر الحساس", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
            value: _isBioEnabled,
            onChanged: (bool value) async {
              await SecurityService.setBiometricEnabled(value);
              setState(() => _isBioEnabled = value);
            },
          ),

          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "إدارة رمز PIN", 
              style: TextStyle(color: isDark ? Colors.blue : Colors.blueAccent, fontWeight: FontWeight.bold)
            ),
          ),

          // خيار تغيير الرمز
          ListTile(
            leading: Icon(Icons.lock_reset, color: isDark ? Colors.white : Colors.black87),
            title: Text("تغيير رمز الدخول PIN", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.black45),
            onTap: () => _showChangePinDialog(context),
          ),

          const Divider(),
          // خيار مسح كافة البيانات الأمنية (Factory Reset)
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text("مسح بيانات الأمان", style: TextStyle(color: Colors.redAccent)),
            onTap: () => _confirmReset(context),
          ),
        ],
      ),
    );
  }

  // دالة لجلب نص توضيحي للثيم
  String _getThemeLabel(String mode) {
    switch (mode) {
      case 'light': return 'الوضع الفاتح';
      case 'dark': return 'الوضع الداكن';
      default: return 'تلقائي (حسب الهاتف)';
    }
  }

  // نافذة اختيار الثيم
  void _showThemePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Text(
            "اختر مظهر التطبيق", 
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 10),
          _buildThemeOption(context, 'system', 'تلقائي (حسب الهاتف)', Icons.brightness_auto),
          _buildThemeOption(context, 'light', 'الوضع الفاتح', Icons.light_mode),
          _buildThemeOption(context, 'dark', 'الوضع الداكن', Icons.dark_mode),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String mode, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSelected = _currentTheme == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : (isDark ? Colors.white54 : Colors.black54)),
      title: Text(label, style: TextStyle(color: isSelected ? Colors.blue : (isDark ? Colors.white : Colors.black87))),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () async {
        await SecurityService.setThemeMode(mode);
        setState(() => _currentTheme = mode);
        
        // تحديث الثيم في التطبيق فوراً
        if (mode == 'dark') themeNotifier.value = ThemeMode.dark;
        else if (mode == 'light') themeNotifier.value = ThemeMode.light;
        else themeNotifier.value = ThemeMode.system;
        
        Navigator.pop(context);
      },
    );
  }

  // حوار تغيير الرمز بأسلوب أمني
  void _showChangePinDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        title: Text(
          "تحديث رمز PIN المشفر", 
          style: TextStyle(color: isDark ? Colors.white : Colors.black87)
        ),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.text, // توحيد مع باقي الشاشات
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: "أدخل الرمز الجديد",
            hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("إلغاء", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.blue : Colors.blueAccent,
            ),
            onPressed: () async {
              if (pinController.text.length >= 4) {
                await SecurityService.saveSecurePIN(pinController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم التحديث بنجاح")));
              }
            },
            child: const Text("تحديث", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // دالة تأكيد مسح بيانات الأمان
  void _confirmReset(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        title: Text(
          "تحذير أمني", 
          style: TextStyle(color: isDark ? Colors.white : Colors.black87)
        ),
        content: Text(
          "هل أنت متأكد من مسح كافة بيانات الدخول؟ سيتم إغلاق التطبيق وتحتاج لضبط رمز جديد عند الفتح.",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("إلغاء", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // مسح البيانات من الخزنة المشفرة
              const storage = FlutterSecureStorage();
              await storage.deleteAll();

              // إغلاق التطبيق نهائياً لإجبار المستخدم على إعادة الإعداد
              SystemNavigator.pop();
            },
            child: const Text("مسح نهائي", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}