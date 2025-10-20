
class IntentNode {
  final String id;
  final String label;
  final String description;
  final List<String> allowedIntents;

  IntentNode({
    required this.id,
    required this.label,
    required this.description,
    required this.allowedIntents,
  });

  factory IntentNode.fromJson(Map<String, dynamic> json) => IntentNode(
        id: json['id'],
        label: json['label'],
        description: json['description'] ?? '',
        allowedIntents:
            (json['allowed_intents'] as List).map((e) => e as String).toList(),
      );
}