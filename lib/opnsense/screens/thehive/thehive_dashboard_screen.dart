import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/thehive_case.dart';
import '../../services/thehive_service.dart';

class TheHiveDashboardScreen extends StatefulWidget {
  const TheHiveDashboardScreen({super.key});

  @override
  State<TheHiveDashboardScreen> createState() => _TheHiveDashboardScreenState();
}

class _TheHiveDashboardScreenState extends State<TheHiveDashboardScreen> {
  late Future<List<TheHiveCase>> _casesFuture;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  _loadCases() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('thehive_url') ?? "";
    final key = prefs.getString('thehive_key') ?? "";
    final service = TheHiveService(baseUrl: url, apiKey: key);
    setState(() {
      _casesFuture = service.getCases();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("TheHive Cases"),
        backgroundColor: Colors.orange.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCases,
          ),
        ],
      ),
      body: FutureBuilder<List<TheHiveCase>>(
        future: _casesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No cases found.", style: TextStyle(color: Colors.white)));
          }

          final cases = snapshot.data!;
          return ListView.builder(
            itemCount: cases.length,
            padding: const EdgeInsets.all(15),
            itemBuilder: (context, index) {
              final caseItem = cases[index];
              return Card(
                color: const Color(0xFF16213E),
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  title: Text(
                    caseItem.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(caseItem.description, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBadge(caseItem.severity, _getSeverityColor(caseItem.severity)),
                          _buildBadge(caseItem.status, Colors.blueGrey),
                        ],
                      ),
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

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low': return Colors.green;
      case 'medium': return Colors.blue;
      case 'high': return Colors.orange;
      case 'critical': return Colors.red;
      default: return Colors.grey;
    }
  }
}
