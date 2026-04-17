class FirewallRule {
  final String description;
  final bool enabled;
  final String protocol;
  final String source;
  final String destination;
  final String action;

  FirewallRule({
    required this.description,
    required this.enabled,
    required this.protocol,
    required this.source,
    required this.destination,
    required this.action,
  });

  // هذا المصنع أصبح الآن ذكياً؛ إذا لم يجد القيمة، يضع نصاً بديلاً بدل أن يعطي خطأ
  factory FirewallRule.fromJson(Map<String, dynamic> json) {
    // الخدمة تكون شغالة إذا كان حقل running يساوي true
    bool isRunning = json['running'] == true;

    return FirewallRule(
      description: json['description'] ?? json['name'] ?? 'No Name',
      enabled: isRunning,
      protocol: 'SVC',
      source: 'Status:',
      destination: isRunning ? 'Running' : 'Stopped',
      // هنا السر: إذا كانت شغالة نعطيها وسم pass لتصبح خضراء في الواجهة
      action: isRunning ? 'pass' : 'block',
    );
  }
}