import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class WazuhAlertsScreen extends StatefulWidget {
  final String serverIp;
  final String authHeader;

  const WazuhAlertsScreen({
    super.key,
    required this.serverIp,
    required this.authHeader,
  });

  @override
  State<WazuhAlertsScreen> createState() => _WazuhAlertsScreenState();
}

class _WazuhAlertsScreenState extends State<WazuhAlertsScreen> {

  // تنسيق الوقت ليصبح محلياً وأنيقاً
  String _formatTimestamp(String isoTimestamp) {
    try {
      DateTime utcTime = DateTime.parse(isoTimestamp);
      return DateFormat('HH:mm:ss | yyyy-MM-dd').format(utcTime.toLocal());
    } catch (e) {
      return isoTimestamp;
    }
  }

  // دالة الحظر في OPNsense
  Future<bool> _blockIpInOpnsense(String ipToBlock) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? opnIp = prefs.getString('opnsense_ip')?.trim();
      String? opnKey = prefs.getString('opnsense_key')?.trim();
      String? opnSecret = prefs.getString('opnsense_secret')?.trim();

      if (opnIp == null || opnKey == null || opnSecret == null) return false;
      if (opnIp.endsWith('/')) opnIp = opnIp.substring(0, opnIp.length - 1);

      final url = Uri.parse('$opnIp/api/firewall/alias_util/add/Blacklist');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$opnKey:$opnSecret'))}',
          'Content-Type': 'application/json',
        },
        body: json.encode({"address": ipToBlock}),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> _fetchAlerts() async {
    final String url = "https://${widget.serverIp}:9200/wazuh-alerts-*/_search?size=50&sort=@timestamp:desc";
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': widget.authHeader,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['hits']['hits'];
    } else {
      throw Exception("Connection Error: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14), // أسود أعمق
      appBar: AppBar(
        elevation: 0,
        title: const Text("SECURITY COMMAND CENTER",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: const Color(0xFF161B22),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.blueAccent),
            onPressed: () => setState(() {}),
          )
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchAlerts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent));
          }
          if (snapshot.hasError) return _buildErrorUI(snapshot.error.toString());
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No threats detected", style: TextStyle(color: Colors.green)));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemBuilder: (context, index) {
              final source = snapshot.data![index]['_source'];
              return _buildAlertCard(source);
            },
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> source) {
    final rule = source['rule'] ?? {};
    final int level = int.parse(rule['level'].toString());
    final String srcIp = source['data']?['srcip'] ?? "Internal";
    final String agent = source['agent']?['name'] ?? "Unknown";
    final Color severityColor = _getLevelColor(level);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: severityColor, width: 4)), // خط جانبي ملون حسب الخطورة
      ),
      child: ExpansionTile(
        iconColor: Colors.white,
        collapsedIconColor: Colors.grey,
        leading: Icon(level >= 10 ? Icons.gpp_maybe_rounded : Icons.security_rounded, color: severityColor),
        title: Text(
          rule['description'] ?? "Undefined Threat",
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            "SOURCE: $srcIp  |  AGENT: $agent",
            style: const TextStyle(color: Colors.blueGrey, fontSize: 10, fontFamily: 'monospace'),
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow("Timestamp", _formatTimestamp(source['@timestamp'])),
                _detailRow("Rule ID", rule['id'] ?? "N/A"),
                _detailRow("Severity Level", level.toString()),
                const SizedBox(height: 12),
                if (srcIp != "Internal" && srcIp != "N/A")
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async => _handleBlock(srcIp),
                      icon: const Icon(Icons.shield_outlined, size: 18),
                      label: Text("TERMINATE CONNECTION (BLOCK $srcIp)"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.8),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  void _handleBlock(String ip) async {
    bool success = await _blockIpInOpnsense(ip);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        content: Text(success ? "SUCCESS: IP $ip blacklisted" : "FAILURE: Could not block IP"),
      ),
    );
  }

  Widget _buildErrorUI(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dns_outlined, color: Colors.redAccent, size: 40),
          const SizedBox(height: 10),
          Text("Backend Connection Failed", style: TextStyle(color: Colors.white.withOpacity(0.7))),
        ],
      ),
    );
  }

  Color _getLevelColor(int level) {
    if (level >= 12) return Colors.purpleAccent; // تهديد حرج جداً
    if (level >= 10) return Colors.redAccent;    // تهديد مرتفع
    if (level >= 5) return Colors.orangeAccent;  // متوسط
    return Colors.blueAccent;                    // منخفض
  }
}