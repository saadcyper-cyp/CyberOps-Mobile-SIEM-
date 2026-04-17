import 'package:flutter/material.dart';
import 'wazuh_agents_screen.dart';
import 'error_detector_screen.dart'; // استيراد صفحة الرادار المنسدلة

class WazuhDashboardScreen extends StatelessWidget {
  const WazuhDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B2F),
      appBar: AppBar(
        title: const Text("لوحة تحكم Wazuh"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent.withOpacity(0.1),
        elevation: 0,
        // إضافة زر لتحديث الحالة العامة
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
            // 1. الوكلاء (Agents)
            _buildCard(context, "الوكلاء (Agents)", Icons.devices, Colors.blue, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const WazuhAgentsScreen()));
            }),

            // 3. سلامة الملفات (FIM)
            _buildCard(context, "سلامة الملفات", Icons.history_edu, Colors.green, () {
              _showComingSoon(context, "سلامة الملفات (FIM)");
            }),

            // 4. اكتشاف الأخطاء (Error Detector) - الرادار الجديد
            _buildCard(
              context,
              "اكتشاف الأخطاء",
              Icons.radar,
              Colors.orange,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ErrorDetectorScreen())),
              isNew: true, // علامة تدل على وجود تنبيهات أو أنها ميزة نشطة
            ),

            // 5. القواعد (Ruleset)
            _buildCard(context, "القواعد", Icons.rule, Colors.purple, () {
              _showComingSoon(context, "إدارة القواعد");
            }),

            // 6. السجلات (Logs)
            _buildCard(context, "السجلات", Icons.list_alt, Colors.grey, () {
              _showComingSoon(context, "سجلات النظام");
            }),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("ميزة $feature ستتوفر قريباً!"),
        backgroundColor: Colors.blueGrey,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // تطوير دالة بناء الكرت لتشمل خيار "المؤشر" (Badge)
  Widget _buildCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap, {bool isNew = false}) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5), width: 1),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, spreadRadius: 2),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 45, color: color),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        // إضافة مؤشر صغير إذا كانت هناك أخطاء (فقط لزر اكتشاف الأخطاء)
        if (isNew)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.priority_high, size: 10, color: Colors.white),
            ),
          ),
      ],
    );
  }
}