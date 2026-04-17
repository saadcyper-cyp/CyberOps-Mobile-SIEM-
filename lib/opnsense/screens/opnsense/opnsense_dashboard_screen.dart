import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// الاستيرادات الخاصة بالصفحات
import 'connect_opnsense_screen.dart';
import 'firewall_status_screen.dart';
import 'alerts_screen.dart';
import 'firewall_alerts_screen.dart'; // ✅ أضفنا هذا السطر

class OPNsenseDashboardScreen extends StatefulWidget {
  const OPNsenseDashboardScreen({super.key});

  @override
  State<OPNsenseDashboardScreen> createState() => _OPNsenseDashboardScreenState();
}

class _OPNsenseDashboardScreenState extends State<OPNsenseDashboardScreen> {
  String serverIp = "جاري التحميل...";

  @override
  void initState() {
    super.initState();
    _loadServerInfo();
  }

  _loadServerInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      serverIp = prefs.getString('opnsense_ip') ?? "غير معروف";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("SOC Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[900],
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const OPNsenseLoginScreen()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),

            const SizedBox(height: 30),
            const Text(
              "Security Modules",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 15),

            // 1. كرت حالة الخدمات (Security Status)
            _buildMenuCard(
              context,
              title: "Security Status",
              subtitle: "مراقبة الخدمات وقواعد الحماية",
              icon: Icons.shield_outlined,
              color: Colors.blue[700]!,
              targetScreen: const FirewallStatusScreen(),
            ),

            // 2. كرت تنبيهات الاختراق (IDS Alerts)
            _buildMenuCard(
              context,
              title: "IDS Alerts",
              subtitle: "تنبيهات نظام كشف التسلل (Real-time)",
              icon: Icons.gpp_maybe_outlined,
              color: Colors.red[700]!,
              targetScreen: const AlertsScreen(),
            ),

            // 3. كرت سجلات الجدار الناري (Firewall Logs) ✅ الجديد هنا
            _buildMenuCard(
              context,
              title: "Firewall Live Logs",
              subtitle: "سجلات حركة مرور الشبكة والمنع",
              icon: Icons.list_alt_rounded,
              color: Colors.orange[800]!, // لون برتقالي لتمييزه
              targetScreen: const FirewallAlertsScreen(),
            ),
          ],
        ),
      ),
    );
  }

  // --- دوال بناء الواجهة (نفس التي لديك) ---
  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.red[900]!.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.dns, color: Colors.green, size: 35),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Connected to Node:", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(serverIp, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    Widget? targetScreen
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          if (targetScreen != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen));
          }
        },
      ),
    );
  }
}