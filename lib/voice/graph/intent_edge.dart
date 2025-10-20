class IntentEdge {
  final String from;
  final String intent;
  final String to;

  IntentEdge({required this.from, required this.intent, required this.to});

  factory IntentEdge.fromJson(Map<String, dynamic> json) =>
      IntentEdge(from: json['from'], intent: json['intent'], to: json['to']);
}