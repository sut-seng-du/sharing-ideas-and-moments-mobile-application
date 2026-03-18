import 'dart:convert';

class Message {
  final int? id;
  final String title;
  final String content;
  final List<String> imagePaths;
  final String? category;
  final DateTime createdAt;

  Message({
    this.id,
    required this.title,
    required this.content,
    this.imagePaths = const [],
    this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imagePaths': jsonEncode(imagePaths),
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      imagePaths: map['imagePaths'] != null 
          ? List<String>.from(jsonDecode(map['imagePaths'])) 
          : [],
      category: map['category'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Message copyWith({
    int? id,
    String? title,
    String? content,
    List<String>? imagePaths,
    String? category,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imagePaths: imagePaths ?? this.imagePaths,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
