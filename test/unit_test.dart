import 'package:flutter_test/flutter_test.dart';
import 'package:sim/models/message.dart';

void main() {
  group('Message Model Tests', () {
    final testDate = DateTime.parse('2026-04-10T12:00:00Z');
    
    final testMessage = Message(
      id: 1,
      title: 'Test Title',
      content: 'Test Content',
      imagePaths: ['path/1', 'path/2'],
      category: 'Moment',
      createdAt: testDate,
      isUploaded: true,
    );

    test('Message.toMap() converts object to correct map', () {
      final map = testMessage.toMap();
      
      expect(map['id'], 1);
      expect(map['title'], 'Test Title');
      expect(map['content'], 'Test Content');
      expect(map['imagePaths'], '["path/1","path/2"]');
      expect(map['category'], 'Moment');
      expect(map['createdAt'], testDate.toIso8601String());
      expect(map['isUploaded'], 1);
    });

    test('Message.fromMap() reconstructs object correctly', () {
      final map = {
        'id': 1,
        'title': 'Test Title',
        'content': 'Test Content',
        'imagePaths': '["path/1","path/2"]',
        'category': 'Moment',
        'createdAt': testDate.toIso8601String(),
        'isUploaded': 1,
      };
      
      final reconstructed = Message.fromMap(map);
      
      expect(reconstructed.id, testMessage.id);
      expect(reconstructed.title, testMessage.title);
      expect(reconstructed.content, testMessage.content);
      expect(reconstructed.imagePaths, testMessage.imagePaths);
      expect(reconstructed.category, testMessage.category);
      expect(reconstructed.createdAt, testMessage.createdAt);
      expect(reconstructed.isUploaded, true);
    });

    test('Message.copyWith() creates a modified copy', () {
      final updated = testMessage.copyWith(title: 'New Title', isUploaded: false);
      
      expect(updated.title, 'New Title');
      expect(updated.isUploaded, false);
      expect(updated.content, testMessage.content); // Unchanged
      expect(updated.id, testMessage.id); // Unchanged
    });

    test('Message factory fromMap handles null imagePaths', () {
      final map = {
        'id': 1,
        'title': 'T',
        'content': 'C',
        'imagePaths': null,
        'category': null,
        'createdAt': DateTime.now().toIso8601String(),
        'isUploaded': 0,
      };
      final msg = Message.fromMap(map);
      expect(msg.imagePaths, isEmpty);
      expect(msg.category, isNull);
    });

    test('Message.fromMap() handles invalid date strings gracefully', () {
      final map = {
        'id': 1,
        'title': 'T',
        'content': 'C',
        'imagePaths': '[]',
        'category': 'Moment',
        'createdAt': 'invalid-date',
        'isUploaded': 0,
      };
      // DateTime.parse will throw on invalid date, checking how model handles it
      expect(() => Message.fromMap(map), throwsA(isA<FormatException>()));
    });
  });
}
