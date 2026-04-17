import 'package:flutter/material.dart';
import '../../services/opnsense_service.dart';
import '../../model/firewall_rule.dart';

class FirewallStatusScreen extends StatefulWidget {
  const FirewallStatusScreen({super.key});

  @override
  State<FirewallStatusScreen> createState() => _FirewallStatusScreenState();
}

class _FirewallStatusScreenState extends State<FirewallStatusScreen> {
  final OPNsenseService _apiService = OPNsenseService();
  late Future<List<FirewallRule>> _rulesFuture;

  @override
  void initState() {
    super.initState();
    _rulesFuture = _apiService.fetchFirewallRules();
  }

  void _refreshData() {
    setState(() {
      _rulesFuture = _apiService.fetchFirewallRules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // لون غامق احترافي (Deep Navy Black)
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text("CYBER COMMAND CENTER",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.blueAccent)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.sync_problem_rounded, color: Colors.blueAccent), onPressed: _refreshData)
        ],
      ),
      body: FutureBuilder<List<FirewallRule>>(
        future: _rulesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          }

          final services = snapshot.data ?? [];

          return Column(
            children: [
              _buildHeaderStats(services), // إحصائيات علوية سريعة
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    final bool isRunning = service.action == 'pass';
                    final Color themeColor = isRunning ? Colors.cyanAccent : Colors.redAccent;

                    return _buildServiceNode(service, isRunning, themeColor);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 1. إحصائيات علوية (Header Stats) - تضفي لمسة احترافية
  Widget _buildHeaderStats(List<FirewallRule> services) {
    int active = services.where((s) => s.action == 'pass').length;
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("TOTAL NODES", "${services.length}", Colors.blueAccent),
          _statItem("ACTIVE", "$active", Colors.cyanAccent),
          _statItem("THREATS", "0", Colors.redAccent),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
        )],
    );
  }

  // 2. كرت الخدمة المطور مع أزرار التحكم
  Widget _buildServiceNode(FirewallRule service, bool isRunning, Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: themeColor.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: themeColor.withOpacity(0.05), blurRadius: 20, spreadRadius: -5)],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: themeColor.withOpacity(0.1),
              child: Icon(isRunning ? Icons.security : Icons.warning_amber_rounded, color: themeColor),
            ),
            title: Text(service.description.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text("Gateway: ${service.destination}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
            trailing: _buildPowerButton(isRunning, themeColor), // زر التشغيل/الإيقاف
          ),

          // شريط "نبض" الشبكة (Network Pulse)
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: isRunning ? 0.7 : 0.1,
                    backgroundColor: Colors.black26,
                    color: themeColor.withOpacity(0.5),
                    minHeight: 2,
                  ),
                ),
                const SizedBox(width: 15),
                Text(isRunning ? "STABLE" : "OFFLINE",
                    style: TextStyle(color: themeColor, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // 3. زر الطاقة التفاعلي (Modern Power Switch)
  Widget _buildPowerButton(bool isRunning, Color themeColor) {
    return GestureDetector(
      onTap: () {
        // هنا يتم وضع كود الـ API لتشغيل أو إيقاف الخدمة
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: themeColor, content: Text("Executing command on ${isRunning ? 'Stop' : 'Start'}..."))
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 35, width: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isRunning ? themeColor.withOpacity(0.1) : Colors.black38,
          border: Border.all(color: isRunning ? themeColor : Colors.white24, width: 1.5),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
              left: isRunning ? 38 : 5,
              top: 5,
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(shape: BoxShape.circle, color: isRunning ? themeColor : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}