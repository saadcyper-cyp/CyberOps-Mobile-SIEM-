import 'package:flutter/material.dart';
import '../../services/wazuh_service.dart';

class WazuhVulnerabilitiesScreen extends StatefulWidget {
  const WazuhVulnerabilitiesScreen({super.key});

  @override
  State<WazuhVulnerabilitiesScreen> createState() => _WazuhVulnerabilitiesScreenState();
}

class _WazuhVulnerabilitiesScreenState extends State<WazuhVulnerabilitiesScreen> {
  List<dynamic> _vulnerabilities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVulnerabilities();
  }

  void _loadVulnerabilities() async {
    setState(() => _isLoading = true);
    // سنطلب ثغرات المانجر (000) كمثال، أو يمكنك تمرير ID أي جهاز آخر
    final data = await WazuhService.getVulnerabilities("000");
    setState(() {
      _vulnerabilities = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("كاشف الثغرات (CVE)"),
        backgroundColor: Colors.orange[900],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : ListView.builder(
        itemCount: _vulnerabilities.length,
        itemBuilder: (context, index) {
          final v = _vulnerabilities[index];
          final severity = v['severity']?.toString().toLowerCase() ?? "low";

          return Card(
            color: Colors.white.withOpacity(0.05),
            child: ListTile(
              leading: Icon(Icons.bug_report,
                  color: severity == "critical" ? Colors.purple : (severity == "high" ? Colors.red : Colors.orange)),
              title: Text(v['condition'] ?? "Unknown Vulnerability",
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: Text("Package: ${v['package_name']} | CVE: ${v['cve']}",
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
              trailing: Text(severity.toUpperCase(),
                  style: TextStyle(color: severity == "critical" ? Colors.purple : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }
}