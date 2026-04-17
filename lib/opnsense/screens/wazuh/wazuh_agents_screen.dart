import 'package:flutter/material.dart';
import '../../services/wazuh_service.dart';

class WazuhAgentsScreen extends StatefulWidget {
  const WazuhAgentsScreen({super.key});

  @override
  State<WazuhAgentsScreen> createState() => _WazuhAgentsScreenState();
}

class _WazuhAgentsScreenState extends State<WazuhAgentsScreen> {
  List<dynamic> _agents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAgentsData();
  }

  // دالة جلب البيانات من السيرفر
  Future<void> _fetchAgentsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await WazuhService.getAgents();
      setState(() {
        _agents = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "فشل في جلب البيانات: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("الأجهزة المتصلة (Agents)"),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAgentsData, // تحديث القائمة
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : _agents.isEmpty
          ? const Center(child: Text("لا توجد أجهزة مسجلة", style: TextStyle(color: Colors.white)))
          : ListView.builder(
        itemCount: _agents.length,
        itemBuilder: (context, index) {
          final agent = _agents[index];
          final bool isOnline = agent['status'] == 'active';

          return Card(
            color: Colors.white.withOpacity(0.05),
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isOnline ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                child: Icon(
                  agent['os']['platform'] == 'windows' ? Icons.window : Icons.terminal,
                  color: isOnline ? Colors.green : Colors.red,
                ),
              ),
              title: Text(
                agent['name'] ?? "جهاز غير معروف",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "IP: ${agent['ip']} | OS: ${agent['os']['name']}",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.circle,
                    size: 12,
                    color: isOnline ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOnline ? "متصل" : "أوفلاين",
                    style: TextStyle(color: isOnline ? Colors.green : Colors.red, fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}