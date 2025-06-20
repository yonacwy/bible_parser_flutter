import 'package:flutter_test/flutter_test.dart';
import 'package:bible_parser_flutter/src/parsers/osis_parser.dart';
import 'package:bible_parser_flutter/src/parsers/usfx_parser.dart';
import 'package:bible_parser_flutter/src/parsers/zxbml_parser.dart';

void main() {
  group('OSIS Parser Tests', () {
    final sampleOsisXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<osis xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace">
  <osisText osisIDWork="KJV">
    <div type="book" osisID="Gen">
      <chapter osisID="Gen.1">
        <verse osisID="Gen.1.1">In the beginning God created the heaven and the earth.</verse>
        <verse osisID="Gen.1.2">And the earth was without form, and void; and darkness was upon the face of the deep.</verse>
      </chapter>
    </div>
  </osisText>
</osis>
''';

    test('OsisParser can parse sample XML', () async {
      final parser = OsisParser(sampleOsisXml);
      
      // Test format detection
      expect(await parser.checkFormat(sampleOsisXml), isTrue);
      
      // Test book parsing
      final books = await parser.parseBooks().toList();
      expect(books, isNotEmpty);
      expect(books.first.id, equals('gen'));
      expect(books.first.title, equals('Genesis'));
      
      // Test verse parsing
      final verses = await parser.parseVerses().toList();
      expect(verses.length, equals(2));
      expect(verses.first.num, equals(1));
      expect(verses.first.chapterNum, equals(1));
      expect(verses.first.bookId, equals('gen'));
      expect(verses.first.text, contains('In the beginning'));
    });
  });

  group('USFX Parser Tests', () {
    final sampleUsfxXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<usfx>
  <book id="GEN">
    <c id="1">
      <v id="1">In the beginning God created the heaven and the earth.</v>
      <v id="2">And the earth was without form, and void; and darkness was upon the face of the deep.</v>
    </c>
  </book>
</usfx>
''';

    test('UsfxParser can parse sample XML', () async {
      final parser = UsfxParser(sampleUsfxXml);
      
      // Test format detection
      expect(await parser.checkFormat(sampleUsfxXml), isTrue);
      
      // Test book parsing
      final books = await parser.parseBooks().toList();
      expect(books, isNotEmpty);
      expect(books.first.id, equals('gen'));
      
      // Test verse parsing
      final verses = await parser.parseVerses().toList();
      expect(verses.length, equals(2));
      expect(verses.first.num, equals(1));
      expect(verses.first.chapterNum, equals(1));
      expect(verses.first.bookId, equals('gen'));
      expect(verses.first.text, contains('In the beginning'));
    });
  });

  group('ZXBML Parser Tests', () {
    final sampleZxbmlXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<bible>
  <book id="GEN">
    <chapter id="1">
      <verse id="1">In the beginning God created the heaven and the earth.</verse>
      <verse id="2">And the earth was without form, and void; and darkness was upon the face of the deep.</verse>
    </chapter>
  </book>
</bible>
''';

    test('ZxbmlParser can parse sample XML', () async {
      final parser = ZxbmlParser(sampleZxbmlXml);
      
      // Test format detection
      expect(await parser.checkFormat(sampleZxbmlXml), isTrue);
      
      // Test book parsing
      final books = await parser.parseBooks().toList();
      expect(books, isNotEmpty);
      expect(books.first.id, equals('gen'));
      
      // Test verse parsing
      final verses = await parser.parseVerses().toList();
      expect(verses.length, equals(2));
      expect(verses.first.num, equals(1));
      expect(verses.first.chapterNum, equals(1));
      expect(verses.first.bookId, equals('gen'));
      expect(verses.first.text, contains('In the beginning'));
    });
  });
}
