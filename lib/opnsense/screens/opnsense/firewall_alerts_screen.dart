import 'package:flutter/material.dart';
import '../../services/opnsense_service.dart';

class FirewallAlertsScreen extends StatefulWidget {
  const FirewallAlertsScreen({super.key});

  @override
  State<FirewallAlertsScreen> createState() => _FirewallAlertsScreenState();
}

class _FirewallAlertsScreenState extends State<FirewallAlertsScreen> {
  final OPNsenseService _apiService = OPNsenseService();

  // دالة لتحديد لون السهم بناءً على البروتوكول
  Color _getProtocolColor(String? proto) {
    switch (proto?.toLowerCase()) {
      case 'tcp': return Colors.blueAccent;
      case 'udp': return Colors.orangeAccent;
      case 'icmp': return Colors.purpleAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // خلفية داكنة (Dark Mode) لنمط الـ SOC
      appBar: AppBar(
        title: const Text(
          "FIREWALL LIVE LOGS",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.blueGrey[900],
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}), // تحديث الصفحة
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _apiService.fetchFirewallLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blue));
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text("No Logs Found or Connection Error",
                    style: TextStyle(color: Colors.grey))
            );
          }

          final logs = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];

              // التحقق من حالة العملية (Pass / Block)
              bool isPass = log['action'] == 'pass';
              String proto = log['protoname'] ?? 'IP';

              return Card(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // أيقونة الحالة
                          Row(
                            children: [
                              Icon(
                                isPass ? Icons.check_circle_outline : Icons.block_flipped,
                                color: isPass ? Colors.greenAccent : Colors.redAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isPass ? "PASSED" : "BLOCKED",
                                style: TextStyle(
                                  color: isPass ? Colors.greenAccent : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          // الوقت والبروتوكول
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getProtocolColor(proto).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              proto.toUpperCase(),
                              style: TextStyle(color: _getProtocolColor(proto), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("SOURCE", style: TextStyle(color: Colors.grey, fontSize: 9)),
                                Text(log['src'] ?? "0.0.0.0", style: const TextStyle(color: Colors.white, fontSize: 13)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text("DESTINATION", style: TextStyle(color: Colors.grey, fontSize: 9)),
                                Text(log['dst'] ?? "0.0.0.0", style: const TextStyle(color: Colors.white, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Interface: ${log['interface']}",
                            style: const TextStyle(color: Colors.blueGrey, fontSize: 10),
                          ),
                          Text(
                            log['label'] ?? "Default Rule",
                            style: const TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic),
                          ),
                        ],
                      )
                    ],
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