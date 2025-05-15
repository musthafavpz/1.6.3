class AIMessage {
  final String content;
  final String role; // 'user' or 'assistant'
  final DateTime timestamp;

  AIMessage({
    required this.content,
    required this.role,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AIMessage.fromJson(Map<String, dynamic> json) {
    return AIMessage(
      content: json['content'] ?? '',
      role: json['role'] ?? 'assistant',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'role': role,
      'timestamp': timestamp.toIso8601String(),
    };
  }
} 