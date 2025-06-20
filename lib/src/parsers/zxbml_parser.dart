import 'dart:async';
import 'package:xml/xml_events.dart';

import 'base_parser.dart';
import '../book.dart';
import '../chapter.dart';
import '../verse.dart';
import '../errors.dart';

/// Parser for the ZXBML Bible format.
class ZxbmlParser extends BaseParser {
  /// ZXBML book ID to canonical book name mapping.
  static const Map<String, String> _bookNames = {
    'ge': 'Genesis',
    'ex': 'Exodus',
    'le': 'Leviticus',
    'nu': 'Numbers',
    'de': 'Deuteronomy',
    'jos': 'Joshua',
    'jdg': 'Judges',
    'ru': 'Ruth',
    '1sa': '1 Samuel',
    '2sa': '2 Samuel',
    '1ki': '1 Kings',
    '2ki': '2 Kings',
    '1ch': '1 Chronicles',
    '2ch': '2 Chronicles',
    'ezr': 'Ezra',
    'ne': 'Nehemiah',
    'es': 'Esther',
    'job': 'Job',
    'ps': 'Psalms',
    'pr': 'Proverbs',
    'ec': 'Ecclesiastes',
    'so': 'Song of Solomon',
    'isa': 'Isaiah',
    'jer': 'Jeremiah',
    'la': 'Lamentations',
    'eze': 'Ezekiel',
    'da': 'Daniel',
    'ho': 'Hosea',
    'joe': 'Joel',
    'am': 'Amos',
    'ob': 'Obadiah',
    'jon': 'Jonah',
    'mic': 'Micah',
    'na': 'Nahum',
    'hab': 'Habakkuk',
    'zep': 'Zephaniah',
    'hag': 'Haggai',
    'zec': 'Zechariah',
    'mal': 'Malachi',
    'mt': 'Matthew',
    'mr': 'Mark',
    'lu': 'Luke',
    'joh': 'John',
    'ac': 'Acts',
    'ro': 'Romans',
    '1co': '1 Corinthians',
    '2co': '2 Corinthians',
    'ga': 'Galatians',
    'eph': 'Ephesians',
    'php': 'Philippians',
    'col': 'Colossians',
    '1th': '1 Thessalonians',
    '2th': '2 Thessalonians',
    '1ti': '1 Timothy',
    '2ti': '2 Timothy',
    'tit': 'Titus',
    'phm': 'Philemon',
    'heb': 'Hebrews',
    'jas': 'James',
    '1pe': '1 Peter',
    '2pe': '2 Peter',
    '1jo': '1 John',
    '2jo': '2 John',
    '3jo': '3 John',
    'jude': 'Jude',
    're': 'Revelation',
  };

  /// Creates a new ZXBML parser.
  ZxbmlParser(super.source);

  @override
  bool checkFormat(String content) {
    // Check for ZXBML format markers
    return content.contains('<zxbml') || content.contains('<ZXBML');
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
          if (event.name == 'book') {
            // Find book ID from attributes
            String bookId = '';
            
            for (var attr in event.attributes) {
              if (attr.name == 'id') {
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
          } else if (event.name == 'chapter' && currentBook != null) {
            // Find chapter number from attributes
            String chapterNumStr = '1';
            
            for (var attr in event.attributes) {
              if (attr.name == 'id') {
                chapterNumStr = attr.value;
                break;
              }
            }
            
            final chapterNum = int.tryParse(chapterNumStr) ?? 1;
            
            currentChapter = Chapter(
              num: chapterNum,
              bookId: currentBook.id,
            );
          } else if (event.name == 'verse' && currentBook != null && currentChapter != null) {
            // Find verse number from attributes
            String verseNumStr = '1';
            
            for (var attr in event.attributes) {
              if (attr.name == 'id') {
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
          if (event.name == 'book' && currentBook != null) {
            yield currentBook;
            currentBook = null;
            currentChapter = null;
          } else if (event.name == 'chapter' && currentBook != null && currentChapter != null) {
            currentBook.addChapter(currentChapter);
            currentChapter = null;
          } else if (event.name == 'verse' && currentBook != null && currentChapter != null && currentVerse != null) {
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
      throw BibleParserException('Error parsing books: $e');
    }
  }

  @override
  Stream<Verse> parseVerses() async* {
    final content = await getContent();
    
    // Current parsing state
    String? currentBookId;
    int? currentChapterNum;
    Verse? currentVerse;
    int verseCount = 0;
    
    // Parse XML using events for memory efficiency
    try {
      final events = await parseEvents(content).toList();
      
      for (final event in events) {
        if (event is XmlStartElementEvent) {
          if (event.name == 'book') {
            // Find book ID from attributes
            String bookId = '';
            
            for (var attr in event.attributes) {
              if (attr.name == 'id') {
                bookId = attr.value.toLowerCase();
                break;
              }
            }
            
            if (bookId.isEmpty) continue;
            currentBookId = bookId;
          } else if (event.name == 'chapter' && currentBookId != null) {
            // Find chapter number from attributes
            String chapterNumStr = '1';
            
            for (var attr in event.attributes) {
              if (attr.name == 'id') {
                chapterNumStr = attr.value;
                break;
              }
            }
            
            currentChapterNum = int.tryParse(chapterNumStr) ?? 1;
          } else if (event.name == 'verse' && currentBookId != null && currentChapterNum != null) {
            // Find verse number from attributes
            String verseNumStr = '1';
            
            for (var attr in event.attributes) {
              if (attr.name == 'id') {
                verseNumStr = attr.value;
                break;
              }
            }
            
            final verseNum = int.tryParse(verseNumStr) ?? 1;
            
            currentVerse = Verse(
              num: verseNum,
              chapterNum: currentChapterNum!,
              text: '',
              bookId: currentBookId!,
            );
          }
        } else if (event is XmlEndElementEvent) {
          if (event.name == 'verse' && currentVerse != null) {
            verseCount++;
            yield currentVerse;
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
      throw BibleParserException('Error parsing verses: $e');
    }
  }

  /// Gets the book number based on its ID.
  int _getBookNum(String bookId) {
    final keys = _bookNames.keys.toList();
    final index = keys.indexOf(bookId);
    return index >= 0 ? index + 1 : 0;
  }

  /// Gets the book name based on its ID.
  String _getBookName(String bookId) {
    return _bookNames[bookId] ?? 'Unknown';
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
