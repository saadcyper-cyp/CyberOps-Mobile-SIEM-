import 'package:flutter/material.dart';
import '../../services/opnsense_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final OPNsenseService _apiService = OPNsenseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("IDS SECURITY EVENTS"),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _apiService.fetchIDSAlerts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }

          final alerts = snapshot.data ?? [];

          if (alerts.isEmpty) {
            return const Center(child: Text("Waiting for new alerts...", style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alertData = alerts[index];

              // 🔴 الحل السبراني: اصطياد البيانات بكل المسميات المحتملة في OPNsense
              String message = alertData['alert'] ?? alertData['msg'] ?? alertData['message'] ?? alertData['event'] ?? "Unknown Threat";
              String sourceIp = alertData['src_ip'] ?? alertData['source'] ?? alertData['source_ip'] ?? "N/A";
              String destIp = alertData['dest_ip'] ?? alertData['destination'] ?? alertData['dest'] ?? "N/A";
              String timestamp = alertData['timestamp'] ?? alertData['time'] ?? "Unknown Time";

              // استخراج الوقت فقط إذا كان طويلاً
              if (timestamp.length > 16) {
                timestamp = timestamp.substring(11, 16);
              }

              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 30),
                  title: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Source: $sourceIp", style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                        Text("Destination: $destIp", style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                      ],
                    ),
                  ),
                  trailing: Text(
                    timestamp,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}