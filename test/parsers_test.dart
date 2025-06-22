import 'package:flutter_test/flutter_test.dart';
import 'package:bible_parser_flutter/src/parsers/osis_parser.dart';
import 'package:bible_parser_flutter/src/parsers/usfx_parser.dart';
import 'package:bible_parser_flutter/src/parsers/zefania_parser.dart';

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
    final sampleOsisXmlAlternativeVersion = '''
<?xml version="1.0" encoding="UTF-8"?>
<osis xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace">
  <osisText osisIDWork="KJV">
    <div type="book" osisID="Gen">
      <chapter osisRef="Gen.1" sID="Gen.1.seID.00001" n="1">
        <verse osisID="Gen.1.1" sID="Gen.1.1.seID.00002" n="1">In the beginning God created the heaven and the earth.<verse eID="Gen.1.1.seID.00002"/>
        <verse osisID="Gen.1.2" sID="Gen.1.2.seID.00003" n="2">And the earth was without form, and void; and darkness was upon the face of the deep.<verse eID="Gen.1.2.seID.00003"/>
      <chapter eID="Gen.1.seID.00001"/>
    </div>
  </osisText>
</osis>
''';
    test('OsisParser can parse sample XML', () async {
      final parser = OsisParser(sampleOsisXml);

      // Test format detection
      expect(parser.checkFormat(sampleOsisXml), isTrue);

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

    test('OsisParser can parse sample XML with alternative version', () async {
      final parser = OsisParser(sampleOsisXmlAlternativeVersion);

      // Test format detection
      expect(parser.checkFormat(sampleOsisXmlAlternativeVersion), isTrue);

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

    final sampleUsfxXmlAlternativeVersion = '''
<?xml version="1.0" encoding="UTF-8"?>
<usfx>
  <book id="GEN">
    <c id="1"/>
      <v id="1">In the beginning God created the heaven and the earth.<ve/>
      <v id="2">And the earth was without form, and void; and darkness was upon the face of the deep.<ve/>
  </book>
</usfx>
''';

    test('UsfxParser can parse sample XML', () async {
      final parser = UsfxParser(sampleUsfxXml);

      // Test format detection
      expect(parser.checkFormat(sampleUsfxXml), isTrue);

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

    test('UsfxParser can parse sample XML with alternative version', () async {
      final parser = UsfxParser(sampleUsfxXmlAlternativeVersion);

      // Test format detection
      expect(parser.checkFormat(sampleUsfxXmlAlternativeVersion), isTrue);

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
    final sampleZefaniaXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<XMLBIBLE>
  <BIBLEBOOK bsname="GEN">
    <CHAPTER cnumber="1">
      <VERS vnumber="1">In the beginning God created the heaven and the earth.</VERS>
      <VERS vnumber="2">And the earth was without form, and void; and darkness was upon the face of the deep.</VERS>
    </CHAPTER>
  </BIBLEBOOK>
</XMLBIBLE>
''';

    test('ZefaniaParser can parse sample XML', () async {
      final parser = ZefaniaParser(sampleZefaniaXml);

      // Test format detection
      expect(parser.checkFormat(sampleZefaniaXml), isTrue);

      // Test book parsing
      final books = await parser.parseBooks().toList();
      expect(books, isNotEmpty);
      expect(books.first.id.toLowerCase(), equals('gen'));

      // Test verse parsing
      final verses = await parser.parseVerses().toList();
      expect(verses.length, equals(2));
      expect(verses.first.num, equals(1));
      expect(verses.first.chapterNum, equals(1));
      expect(verses.first.bookId.toLowerCase(), equals('gen'));
      expect(verses.first.text, contains('In the beginning'));
    });
  });
}
