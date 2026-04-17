class TheHiveCase {
  final String title;
  final String description;
  final String severity;
  final String status;
  final String assignee;
  final DateTime createdAt;

  TheHiveCase({
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    required this.assignee,
    required this.createdAt,
  });

  factory TheHiveCase.fromJson(Map<String, dynamic> json) {
    return TheHiveCase(
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? 'No Description',
      severity: _mapSeverity(json['severity']),
      status: json['status'] ?? 'Open',
      assignee: json['assignee'] ?? 'Unassigned',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['startDate'] ?? 0),
    );
  }

  static String _mapSeverity(int? severity) {
    switch (severity) {
      case 1: return 'Low';
      case 2: return 'Medium';
      case 3: return 'High';
      case 4: return 'Critical';
      default: return 'Unknown';
    }
  }
}
