import 'dart:convert';

class Message {
  final int? id;
  final String title;
  final String content;
  final String? imagePath;
  final DateTime createdAt;

  Message({
    this.id,
    required this.title,
    required this.content,
    this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      imagePath: map['imagePath'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Message copyWith({
    int? id,
    String? title,
    String? content,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
