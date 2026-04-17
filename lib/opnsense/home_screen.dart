import 'package:flutter/material.dart';
import 'package:soc/opnsense/screens/opnsense/auth_mobile/setting/security_settings_screen.dart';
import 'package:soc/opnsense/screens/opnsense/connect_opnsense_screen.dart';
import 'package:soc/opnsense/screens/thehive/thehive_login_screen.dart';
import 'package:soc/opnsense/screens/wazuh/indexer/wazuh_indexer_login.dart';
import 'package:soc/opnsense/screens/wazuh/wazuh_login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("نظام SOC المتنقل"),
        centerTitle: true,
        backgroundColor: isDark ? Colors.blueGrey.shade900 : const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_suggest, color: isDark ? Colors.blue : Colors.blueAccent),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const SecuritySettingsScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              "لوحة تحكم الأنظمة Security Console", 
              style: TextStyle(fontSize: 18, color: isDark ? Colors.grey : Colors.blueGrey)
            ),
            const SizedBox(height: 30),

            Expanded(
              child: ListView(
                children: [
                  // 1. زر نظام OPNsense
                  SOCToolButton(
                    title: "تحكم OPNsense Firewall",
                    icon: Icons.block,
                    color: Colors.redAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OPNsenseLoginScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // 2. زر نظام Wazuh (تم التعديل هنا ليرتبط بالشاشة الجديدة)
                  SOCToolButton(
                    title: "تنبيهات Wazuh SIEM",
                    icon: Icons.notifications_active,
                    color: Colors.blue,
                    onPressed: () {
                      // الانتقال لشاشة تسجيل دخول وازه التي برمجناها
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WazuhLoginScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // 3. زر نظام TheHive
                  SOCToolButton(
                    title: "قضايا TheHive Investigation",
                    icon: Icons.assignment_turned_in,
                    color: Colors.orange,
                    onPressed: () {
                      // الانتقال لشاشة تسجيل دخول TheHive الجديدة
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TheHiveLoginScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // أضف هذا الزر داخل الـ ListView في صفحة HomeScreen
                  SOCToolButton(
                    title: "مركز التنبيهات (Port 9200)",
                    icon: Icons.security_update_warning,
                    color: Colors.orange.shade900, // لون مميز للتنبيهات
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WazuhIndexerLoginScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// الودجت الخاص بالزر (كما هو في كودك)
class SOCToolButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const SOCToolButton({
    super.key, required this.title, required this.icon, required this.color, required this.onPressed
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 90,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? color.withOpacity(0.9) : color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: isDark ? 5 : 2,
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 40, color: Colors.white),
        label: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}