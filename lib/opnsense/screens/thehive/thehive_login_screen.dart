import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/thehive_service.dart';
import 'thehive_dashboard_screen.dart';

class TheHiveLoginScreen extends StatefulWidget {
  const TheHiveLoginScreen({super.key});

  @override
  State<TheHiveLoginScreen> createState() => _TheHiveLoginScreenState();
}

class _TheHiveLoginScreenState extends State<TheHiveLoginScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlController.text = prefs.getString('thehive_url') ?? "http://";
      _keyController.text = prefs.getString('thehive_key') ?? "";
    });
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    final url = _urlController.text.trim();
    final key = _keyController.text.trim();

    final service = TheHiveService(baseUrl: url, apiKey: key);
    final success = await service.testConnection();

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('thehive_url', url);
      await prefs.setString('thehive_key', key);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TheHiveDashboardScreen()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("فشل الاتصال بـ TheHive. تأكد من العنوان والمفتاح.")),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("TheHive Connection"),
        backgroundColor: Colors.orange.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_turned_in, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "TheHive URL",
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange.shade900)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _keyController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "API Key",
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange.shade900)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
              ),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.orange)
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade900),
                      onPressed: _handleLogin,
                      child: const Text("Connect to TheHive", style: TextStyle(color: Colors.white)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
