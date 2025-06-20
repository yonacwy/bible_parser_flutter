import 'package:flutter_test/flutter_test.dart';
import 'package:bible_parser_flutter/bible_parser_flutter.dart';

void main() {
  group('Bible Parser Core Classes', () {
    test('Book class exists with correct properties', () {
      final book = Book(id: 'gen', num: 1, title: 'Genesis');
      expect(book.id, equals('gen'));
      expect(book.num, equals(1));
      expect(book.title, equals('Genesis'));
    });
    
    test('Chapter class exists with correct properties', () {
      final chapter = Chapter(num: 1, bookId: 'gen');
      expect(chapter.num, equals(1));
      expect(chapter.bookId, equals('gen'));
    });
    
    test('Verse class exists with correct properties', () {
      final verse = Verse(
        num: 1, 
        chapterNum: 1, 
        text: 'In the beginning God created the heaven and the earth.', 
        bookId: 'gen'
      );
      expect(verse.num, equals(1));
      expect(verse.chapterNum, equals(1));
      expect(verse.text, equals('In the beginning God created the heaven and the earth.'));
      expect(verse.bookId, equals('gen'));
    });
  });
}
