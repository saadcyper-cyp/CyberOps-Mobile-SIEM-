import 'package:flutter/material.dart';

class WazuhLogDetailScreen extends StatelessWidget {
  final Map<String, dynamic> logData;

  const WazuhLogDetailScreen({super.key, required this.logData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // لون داكن احترافي
      appBar: AppBar(
        title: const Text("تفاصيل السجل التقنية"),
        backgroundColor: Colors.blueGrey[900],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 20),
            _buildDetailCard("الوصف", logData['description'] ?? "لا يوجد", Icons.description, Colors.blue),
            _buildDetailCard("المستوى (Level)", logData['level']?.toString() ?? "info", Icons.signal_cellular_alt, _getLevelColor()),
            _buildDetailCard("الوسم (Tag)", logData['tag'] ?? "N/A", Icons.label_important, Colors.orange),
            _buildDetailCard("الوقت", logData['timestamp'] ?? "N/A", Icons.access_time, Colors.green),
            const SizedBox(height: 20),
            const Text("البيانات الخام (Raw JSON):", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueGrey.withOpacity(0.5)),
              ),
              child: Text(
                logData.toString(), // يعرض الـ JSON بالكامل للاحترافية
                style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.security_update_warning, size: 60, color: _getLevelColor()),
          const SizedBox(height: 10),
          Text(
            "تحليل الحدث الأمني",
            style: TextStyle(color: _getLevelColor(), fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        subtitle: Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Color _getLevelColor() {
    String level = logData['level']?.toString().toLowerCase() ?? "info";
    if (level == "error" || level == "critical") return Colors.redAccent;
    if (level == "warning") return Colors.orangeAccent;
    return Colors.blueAccent;
  }
}