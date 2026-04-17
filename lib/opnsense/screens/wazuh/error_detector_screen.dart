import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../services/wazuh_service.dart';
import '../../services/security_service.dart'; // استيراد خدمة البصمة
import '../../services/opnsense_service.dart'; // استيراد خدمة الفايروال

class ErrorDetectorScreen extends StatefulWidget {
  const ErrorDetectorScreen({super.key});

  @override
  State<ErrorDetectorScreen> createState() => _ErrorDetectorScreenState();
}

class _ErrorDetectorScreenState extends State<ErrorDetectorScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _allAlerts = [];
  List<dynamic> _displayedAlerts = [];
  String _currentFilter = "ALL";
  bool _isLoading = true;
  int _criticalCount = 0;

  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _fetchAndAnalyze();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndAnalyze() async {
    setState(() => _isLoading = true);
    try {
      final data = await WazuhService.getSecurityAlerts();
      _allAlerts = data;
      _applyFilter(_currentFilter);
      _criticalCount = _allAlerts.where((a) => _lvl(a) >= 10).length;
    } catch (e) {
      _allAlerts = [];
    }
    setState(() => _isLoading = false);
  }

  void _applyFilter(String filter) {
    _currentFilter = filter;
    setState(() {
      if (filter == "ALL") _displayedAlerts = _allAlerts;
      else if (filter == "INFO") _displayedAlerts = _allAlerts.where((a) => _lvl(a) < 5).toList();
      else if (filter == "WARN") _displayedAlerts = _allAlerts.where((a) => _lvl(a) >= 5 && _lvl(a) < 10).toList();
      else if (filter == "CRITICAL") _displayedAlerts = _allAlerts.where((a) => _lvl(a) >= 10).toList();
    });
  }

  int _lvl(dynamic a) => int.tryParse(a['level']?.toString() ?? "0") ?? 0;

  String _getThreatType(String desc) {
    desc = desc.toLowerCase();
    if (desc.contains("login") || desc.contains("auth") || desc.contains("password")) return "AUTH-VIOLATION";
    if (desc.contains("file") || desc.contains("integrity")) return "FIM-ALERT";
    if (desc.contains("network") || desc.contains("port")) return "NETWORK-SCAN";
    if (desc.contains("attack") || desc.contains("exploit")) return "ZERO-DAY-EXPLOIT";
    return "SYSTEM-ANOMALY";
  }

  // --- دالة الحظر الجديدة (Logic) ---
  Future<void> _handleBlockAction(dynamic alert) async {
    // محاولة استخراج الـ IP من أكثر من مكان محتمل في بيانات Wazuh
    String? srcIp = alert['data']?['srcip'] ?? alert['data']?['ip'] ?? alert['location'];

    if (srcIp == null || srcIp.isEmpty || srcIp.contains("->")) {
      _showCyberSnackBar("ERROR: CANNOT EXTRACT VALID IP", isError: true);
      return;
    }

    // 1. طلب البصمة أولاً
// نمرر الـ context لكي تظهر النافذة
    bool isAuthenticated = await SecurityService.authenticate(context);

    if (isAuthenticated) {
      _showCyberSnackBar("INITIATING FIREWALL BLOCK FOR: $srcIp");

      // 2. إرسال أمر الحظر لـ OPNsense
      bool success = await OPNsenseService().blockIpAddress(srcIp);

      if (success) {
        _showCyberSnackBar("SUCCESS: $srcIp IS NOW BLACKLISTED", isError: false);
      } else {
        _showCyberSnackBar("FAILED: CHECK OPNSENSE API CONNECTION", isError: true);
      }
    } else {
      _showCyberSnackBar("AUTH FAILED: ACTION ABORTED", isError: true);
    }
  }

  void _showCyberSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0D0D14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: isError ? Colors.redAccent : const Color(0xFF00FFCC), width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        content: Text(message,
            style: TextStyle(
                color: isError ? Colors.redAccent : const Color(0xFF00FFCC),
                fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold
            )
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070B),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHUD(),
            _buildFilterNeonTabs(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FFCC)))
                  : _displayedAlerts.isEmpty
                  ? _buildNoThreats()
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _displayedAlerts.length,
                itemBuilder: (context, index) => _buildCyberCard(_displayedAlerts[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHUD() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D14),
        border: const Border(bottom: BorderSide(color: Color(0xFF1A1A24), width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("GLOBAL THREAT RADAR", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 5),
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _radarController,
                    builder: (_, child) => Transform.rotate(angle: _radarController.value * 2 * math.pi, child: child),
                    child: const Icon(Icons.radar, color: Color(0xFF00FFCC), size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text("SCANNING LIVE NETWORK...", style: TextStyle(color: Color(0xFF00FFCC), fontSize: 10, fontFamily: 'monospace')),
                ],
              )
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _criticalCount > 0 ? const Color(0xFFFF003C).withOpacity(0.1) : Colors.green.withOpacity(0.1),
              border: Border.all(color: _criticalCount > 0 ? const Color(0xFFFF003C) : Colors.greenAccent),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(_criticalCount > 0 ? "CRITICAL" : "SECURE", style: TextStyle(color: _criticalCount > 0 ? const Color(0xFFFF003C) : Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                Text("$_criticalCount", style: TextStyle(color: _criticalCount > 0 ? const Color(0xFFFF003C) : Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterNeonTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ["ALL", "INFO", "WARN", "CRITICAL"].map((f) => _neonTab(f)).toList(),
      ),
    );
  }

  Widget _neonTab(String label) {
    bool active = _currentFilter == label;
    Color tabColor = label == "CRITICAL" ? const Color(0xFFFF003C) : const Color(0xFF00FFCC);

    return GestureDetector(
      onTap: () => _applyFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? tabColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: active ? tabColor : Colors.white12),
        ),
        child: Text(label, style: TextStyle(color: active ? tabColor : Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCyberCard(dynamic alert) {
    int level = _lvl(alert);
    String desc = alert['description']?.toString() ?? "UNKNOWN DATA";
    String threatType = _getThreatType(desc);

    Color mainColor = level >= 12 ? const Color(0xFFFF003C)
        : (level >= 7 ? const Color(0xFFFF9900) : const Color(0xFF00BFFF));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: mainColor.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Container(width: 4, height: double.infinity, color: mainColor),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: mainColor.withOpacity(0.1), border: Border.all(color: mainColor)),
                  child: Text("[$threatType]", style: TextStyle(color: mainColor, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                ),
                const SizedBox(height: 6),
                Text(desc.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text("TIME: ${alert['timestamp']} | LVL: $level", style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace')),
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.black,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _terminalText("TARGET LOCATION", alert['location'] ?? "Unknown/Localhost", Colors.white70),
                    const Divider(color: Color(0xFF1A1A24), height: 20),
                    _terminalText("RAW PAYLOAD DATA", alert['full_log'] ?? alert['log'] ?? "No payload detected", const Color(0xFF00FFCC)),
                    const SizedBox(height: 20),

                    // --- الزر البرمجي المعدل بالكامل ---
                    if (level >= 10)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF003C).withOpacity(0.1),
                            side: const BorderSide(color: Color(0xFFFF003C)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _handleBlockAction(alert), // استدعاء دالة الحظر الجديدة
                          icon: const Icon(Icons.security, color: Color(0xFFFF003C), size: 16),
                          label: const Text("BLOCK IP & ISOLATE", style: TextStyle(color: Color(0xFFFF003C), fontWeight: FontWeight.bold)),
                        ),
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _terminalText(String title, String value, Color valColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("> $title:", style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: valColor, fontSize: 12, fontFamily: 'monospace', height: 1.5)),
      ],
    );
  }

  Widget _buildNoThreats() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.greenAccent.withOpacity(0.2)),
          const SizedBox(height: 20),
          const Text("NETWORK IS SECURE", style: TextStyle(color: Colors.greenAccent, letterSpacing: 3, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}