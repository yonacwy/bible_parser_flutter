import 'dart:async';
import 'package:xml/xml_events.dart';

import 'base_parser.dart';
import '../book.dart';
import '../chapter.dart';
import '../verse.dart';
import '../errors.dart';

/// Parser for the Zefania Bible format.
class ZefaniaParser extends BaseParser {
  /// Zefania book ID to canonical book name mapping.
  static const Map<String, String> _bookNames = {
    'Gen': 'Genesis',
    'Exod': 'Exodus',
    'Lev': 'Leviticus',
    'Num': 'Numbers',
    'Deut': 'Deuteronomy',
    'Josh': 'Joshua',
    'Judg': 'Judges',
    'Ruth': 'Ruth',
    '1Sam': '1 Samuel',
    '2Sam': '2 Samuel',
    '1Kgs': '1 Kings',
    '2Kgs': '2 Kings',
    '1Chr': '1 Chronicles',
    '2Chr': '2 Chronicles',
    'Ezra': 'Ezra',
    'Neh': 'Nehemiah',
    'Esth': 'Esther',
    'Job': 'Job',
    'Ps': 'Psalms',
    'Prov': 'Proverbs',
    'Eccl': 'Ecclesiastes',
    'Song': 'Song of Solomon',
    'Isa': 'Isaiah',
    'Jer': 'Jeremiah',
    'Lam': 'Lamentations',
    'Ezek': 'Ezekiel',
    'Dan': 'Daniel',
    'Hos': 'Hosea',
    'Joel': 'Joel',
    'Amos': 'Amos',
    'Obad': 'Obadiah',
    'Jonah': 'Jonah',
    'Mic': 'Micah',
    'Nah': 'Nahum',
    'Hab': 'Habakkuk',
    'Zeph': 'Zephaniah',
    'Hag': 'Haggai',
    'Zech': 'Zechariah',
    'Mal': 'Malachi',
    'Matt': 'Matthew',
    'Mark': 'Mark',
    'Luke': 'Luke',
    'John': 'John',
    'Acts': 'Acts',
    'Rom': 'Romans',
    '1Cor': '1 Corinthians',
    '2Cor': '2 Corinthians',
    'Gal': 'Galatians',
    'Eph': 'Ephesians',
    'Phil': 'Philippians',
    'Col': 'Colossians',
    '1Thess': '1 Thessalonians',
    '2Thess': '2 Thessalonians',
    '1Tim': '1 Timothy',
    '2Tim': '2 Timothy',
    'Titus': 'Titus',
    'Phlm': 'Philemon',
    'Heb': 'Hebrews',
    'Jas': 'James',
    '1Pet': '1 Peter',
    '2Pet': '2 Peter',
    '1John': '1 John',
    '2John': '2 John',
    '3John': '3 John',
    'Jude': 'Jude',
    'Rev': 'Revelation',
  };

  /// Creates a new Zefania parser.
  ZefaniaParser(super.source);

  @override
  bool checkFormat(String content) {
    // Check for Zefania format markers
    return content.contains('<XMLBIBLE') || content.contains('<XMLBIBLE>');
  }

  @override
  Stream<Book> parseBooks() async* {
    final content = await getContent();

    // Current parsing state
    Book? currentBook;
    Chapter? currentChapter;
    Verse? currentVerse;

    // Parse XML using events for memory efficiency
    try {
      final events = await parseEvents(content).toList();

      for (final event in events) {
        if (event is XmlStartElementEvent) {
          if (event.name == 'BIBLEBOOK') {
            // Find book ID from attributes
            String bookId = '';

            for (var attr in event.attributes) {
              if (attr.name == 'bsname') {
                bookId = attr.value;
                break;
              }
            }

            if (bookId.isNotEmpty) {
              bookId = bookId.toLowerCase();
              final bookNum = _getBookNum(bookId);
              final bookName = _getBookName(bookId);

              currentBook = Book(
                id: bookId,
                num: bookNum,
                title: bookName,
              );
            }
          } else if (event.name == 'CHAPTER' && currentBook != null) {
            // Find chapter number from attributes
            String chapterNumStr = '1';

            for (var attr in event.attributes) {
              if (attr.name == 'cnumber') {
                chapterNumStr = attr.value;
                break;
              }
            }

            final chapterNum = int.tryParse(chapterNumStr) ?? 1;

            currentChapter = Chapter(
              num: chapterNum,
              bookId: currentBook.id,
            );
          } else if (event.name == 'VERS' &&
              currentBook != null &&
              currentChapter != null) {
            // Find verse number from attributes
            String verseNumStr = '1';

            for (var attr in event.attributes) {
              if (attr.name == 'vnumber') {
                verseNumStr = attr.value;
                break;
              }
            }

            final verseNum = int.tryParse(verseNumStr) ?? 1;

            // Verse text will be collected in the character events
            currentVerse = Verse(
              num: verseNum,
              chapterNum: currentChapter.num,
              text: '',
              bookId: currentBook.id,
            );
          }
        } else if (event is XmlEndElementEvent) {
          if (event.name == 'BIBLEBOOK' && currentBook != null) {
            yield currentBook;
            currentBook = null;
            currentChapter = null;
          } else if (event.name == 'CHAPTER' &&
              currentBook != null &&
              currentChapter != null) {
            currentBook.addChapter(currentChapter);
            currentChapter = null;
          } else if (event.name == 'VERS' &&
              currentBook != null &&
              currentChapter != null &&
              currentVerse != null) {
            currentChapter.addVerse(currentVerse);
            currentVerse = null;
          }
        } else if (event is XmlTextEvent && currentVerse != null) {
          // Append text to current verse
          final newText = currentVerse.text + event.value.trim();
          currentVerse = Verse(
            num: currentVerse.num,
            chapterNum: currentVerse.chapterNum,
            text: newText,
            bookId: currentVerse.bookId,
          );
        }
      }
    } catch (e, stackTrace) {
      throw BibleParserException('Error parsing books: $e\n$stackTrace');
    }
  }

  @override
  Stream<Verse> parseVerses() async* {
    final content = await getContent();

    // Current parsing state
    String? currentBookId;
    int? currentChapterNum;
    Verse? currentVerse;

    // Parse XML using events for memory efficiency
    try {
      final events = await parseEvents(content).toList();

      for (final event in events) {
        if (event is XmlStartElementEvent) {
          if (event.name == 'BIBLEBOOK') {
            // Find book ID from attributes
            String bookId = '';

            for (var attr in event.attributes) {
              if (attr.name == 'bsname') {
                bookId = attr.value;
                break;
              }
            }

            if (bookId.isEmpty) continue;
            currentBookId = bookId;
          } else if (event.name == 'CHAPTER' && currentBookId != null) {
            // Find chapter number from attributes
            String chapterNumStr = '1';

            for (var attr in event.attributes) {
              if (attr.name == 'cnumber') {
                chapterNumStr = attr.value;
                break;
              }
            }

            currentChapterNum = int.tryParse(chapterNumStr) ?? 1;
          } else if (event.name == 'VERS' &&
              currentBookId != null &&
              currentChapterNum != null) {
            // Find verse number from attributes
            String verseNumStr = '1';

            for (var attr in event.attributes) {
              if (attr.name == 'vnumber') {
                verseNumStr = attr.value;
                break;
              }
            }

            final verseNum = int.tryParse(verseNumStr) ?? 1;

            currentVerse = Verse(
              num: verseNum,
              chapterNum: currentChapterNum,
              text: '',
              bookId: currentBookId,
            );
          }
        } else if (event is XmlEndElementEvent) {
          if (event.name == 'VERS' && currentVerse != null) {
            yield currentVerse;
            currentVerse = null;
          }
        } else if (event is XmlTextEvent && currentVerse != null) {
          // Append text to current verse
          final trimmedText = event.value.trim();
          if (trimmedText.isNotEmpty) {
            final newText = currentVerse.text + trimmedText;
            currentVerse = Verse(
              num: currentVerse.num,
              chapterNum: currentVerse.chapterNum,
              text: newText,
              bookId: currentVerse.bookId,
            );
          }
        }
      }
    } catch (e, stackTrace) {
      throw BibleParserException('Error parsing verses: $e\n$stackTrace');
    }
  }

 /// Gets the book number based on its ID.
  int _getBookNum(String bookId) {
    final keys = _bookNames.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      if (bookId.toLowerCase().startsWith(keys[i].toLowerCase())) {
        return i + 1;
      }
    }
    return 0;
  }

  /// Gets the book name based on its ID.
  String _getBookName(String bookId) {
    for (final entry in _bookNames.entries) {
      if (bookId.toLowerCase().startsWith(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return 'Unknown';
  }

  /// Parses XML events from the content string.
  Stream<XmlEvent> parseEvents(String content) {
    try {
      final events = XmlEventDecoder().convert(content);
      return Stream.fromIterable(events);
    } catch (e) {
      // Handle XML parsing errors
      throw BibleParserException('Error parsing XML: $e');
    }
  }
}
