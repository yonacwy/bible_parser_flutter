import 'dart:async';
import 'package:xml/xml_events.dart';

import 'base_parser.dart';
import '../book.dart';
import '../chapter.dart';
import '../verse.dart';
import '../errors.dart';

/// Parser for the OSIS Bible format.
class OsisParser extends BaseParser {
  /// OSIS book ID to canonical book name mapping.
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

  /// Creates a new OSIS parser.
  OsisParser(dynamic source) : super(source);

  @override
  bool checkFormat(String content) {
    // Check for OSIS format markers
    return content.contains('<osis') || content.contains('<osisText');
  }

  @override
  Stream<Book> parseBooks() async* {
    print('OsisParser.parseBooks() called');
    final content = await getContent();
    print('Content loaded for books, length: ${content.length}');
    print(
        'First 100 chars: ${content.substring(0, content.length > 100 ? 100 : content.length)}');

    // Current parsing state
    Book? currentBook;
    Chapter? currentChapter;
    Verse? currentVerse;
    int bookCount = 0;

    // Parse XML using events for memory efficiency
    try {
      final events = await parseEvents(content).toList();
      print('XML events collected for books, count: ${events.length}');

      // Debug: Print the first 10 events to see what we're working with
      print('First 10 XML events:');
      for (int i = 0; i < events.length && i < 10; i++) {
        final event = events[i];
        if (event is XmlStartElementEvent) {
          print(
              '  Event $i: Start element: ${event.name}, attributes: ${event.attributes}');
        } else if (event is XmlEndElementEvent) {
          print('  Event $i: End element: ${event.name}');
        } else if (event is XmlTextEvent) {
          print(
              '  Event $i: Text: ${event.text.trim().substring(0, event.text.trim().length > 20 ? 20 : event.text.trim().length)}...');
        } else {
          print('  Event $i: Other event type: ${event.runtimeType}');
        }
      }

      for (final event in events) {
        if (event is XmlStartElementEvent) {
          if (event.name == 'div') {
            // Check if this is a book div by looking for type="book" attribute
            bool isBookDiv = false;
            for (var attr in event.attributes) {
              if (attr.name == 'type' && attr.value == 'book') {
                isBookDiv = true;
                break;
              }
            }

            // Skip if not a book div
            if (!isBookDiv) continue;

            // Find the osisID attribute
            String osisID = '';
            for (var attr in event.attributes) {
              if (attr.name == 'osisID') {
                osisID = attr.value;
                break;
              }
            }

            if (osisID.isNotEmpty) {
              final bookId = osisID.toLowerCase();
              final bookNum = _getBookNum(bookId);
              final bookName = _getBookName(bookId);

              currentBook = Book(
                id: bookId,
                num: bookNum,
                title: bookName,
              );
            }
          // Some osis xml version use <chapter eID=""/> as end tags. Without the explicit check for eID here, those tags will be wrongly marked as start tags.
          } else if (event.name == 'chapter' && currentBook != null && !event.attributes.any((attr) => attr.name == 'eID')) {
            // Find chapter number from attributes
            String chapterNumStr = '1';
            String attrName = '';

            for (var attr in event.attributes) {
              if (attr.name == 'n') {
                chapterNumStr = attr.value;
                attrName = attr.name;
                break;
              } else if (attr.name == 'osisRef') {
                chapterNumStr = attr.value;
                attrName = attr.name;
                break;
              } else if (attr.name == 'osisID') {
                chapterNumStr = attr.value;
                attrName = attr.name;
                break;
              }
            }

            // Extract chapter number from osisID (e.g., "Gen.1" -> "1")
            if (attrName == 'osisID' && chapterNumStr.contains('.')) {
              chapterNumStr = chapterNumStr.split('.').last;
            } else if (attrName == 'osisRef' && chapterNumStr.contains('.')) {
              chapterNumStr = chapterNumStr.split('.').last;
            }

            final chapterNum = int.tryParse(chapterNumStr) ?? 1;

            currentChapter = Chapter(
              num: chapterNum,
              bookId: currentBook.id,
            );
            // Some osis xml version use <verse eID=""/> as end tags. Without the explicit check for eID here, those tags will be wrongly marked as start tags.
          } else if (event.name == 'verse' &&
              currentBook != null &&
              currentChapter != null &&
              !event.attributes.any((attr) => attr.name == 'eID')) {
            // Find verse attributes
            String verseOsisID = '';
            String verseNum = '1';

            for (var attr in event.attributes) {
              if (attr.name == 'n') {
                verseNum = attr.value;
              } else if (attr.name == 'osisID') {
                verseOsisID = attr.value;
              }
            }

            // Extract verse number from osisID (e.g., "Gen.1.1" -> "1") or use 'n' attribute
            String verseNumStr = verseNum;
            if (verseOsisID.isNotEmpty) {
              final parts = verseOsisID.split('.');
              if (parts.length > 2) {
                verseNumStr = parts[2];
              }
            }

            final verseNumber = int.tryParse(verseNumStr) ?? 1;

            // Verse text will be collected in the character events
            currentVerse = Verse(
              num: verseNumber,
              chapterNum: currentChapter.num,
              text: '',
              bookId: currentBook.id,
            );
            // Some osis xml version use <chapter eID=""/> as end tags for chapters. This catches such cases..
          } else if(event.name == 'chapter' && currentBook != null && currentChapter != null && event.attributes.any((attr) => attr.name == 'eID')){
            // End of chapter - add to current book
            currentBook.addChapter(currentChapter);
            currentChapter = null;
          }
          // Some osis xml version use <verse eID=""/> as end tags for verses. This catches such cases.
          else if(event.name == 'verse' && currentBook != null && currentChapter != null && currentVerse != null && event.attributes.any((attr) => attr.name == 'eID')){
            // End of verse - add to current chapter
            currentChapter.addVerse(currentVerse);
            currentVerse = null;
          }
        } else if (event is XmlEndElementEvent) {
          if (event.name == 'div' && currentBook != null) {
            // End of book div - we rely on the element name and current state to determine if this is the end of a book
            bookCount++;
            print('Yielding book: ${currentBook.id} (${currentBook.title})');
            // Directly yield the book instead of using a stream controller
            yield currentBook;
            currentBook = null;
            currentChapter = null;
            currentVerse = null;
          } else if (event.name == 'chapter' &&
              currentBook != null &&
              currentChapter != null) {
            // End of chapter - add to current book
            currentBook.addChapter(currentChapter);
            currentChapter = null;
          } else if (event.name == 'verse' &&
              currentBook != null &&
              currentChapter != null &&
              currentVerse != null) {
            // End of verse - add to current chapter
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

      print(
          'OsisParser.parseBooks() completed. Total books yielded: $bookCount');
    } catch (e, stackTrace) {
      print('Error in parseBooks: $e');
      print('Stack trace: $stackTrace');
      rethrow;
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


    try {
      // Parse XML using events for memory efficiency
      final events = await parseEvents(content).toList();

      for (final event in events) {
        if (event is XmlStartElementEvent) {
          if (event.name == 'div') {
            // Check if this is a book div by looking for type="book" attribute
            bool isBookDiv = false;
            for (var attr in event.attributes) {
              if (attr.name == 'type' && attr.value == 'book') {
                isBookDiv = true;
                break;
              }
            }

            // Skip if not a book div
            if (!isBookDiv) continue;

            // Find the osisID attribute
            String osisID = '';
            for (var attr in event.attributes) {
              if (attr.name == 'osisID') {
                osisID = attr.value;
                break;
              }
            }

            if (osisID.isNotEmpty) {
              currentBookId = osisID.toLowerCase();
            }
          } else if (event.name == 'chapter' && currentBookId != null) {
            // Find chapter number from attributes
            String chapterNumStr = '1';
            String attrName = '';

            for (var attr in event.attributes) {
              if (attr.name == 'n') {
                chapterNumStr = attr.value;
                attrName = attr.name;
                break;
              } else if (attr.name == 'osisRef') {
                chapterNumStr = attr.value;
                attrName = attr.name;
                break;
              } else if (attr.name == 'osisID') {
                chapterNumStr = attr.value;
                attrName = attr.name;
                break;
              }
            }

            // Extract chapter number from osisID (e.g., "Gen.1" -> "1")
            if (attrName == 'osisID' && chapterNumStr.contains('.')) {
              chapterNumStr = chapterNumStr.split('.').last;
            } else if (attrName == 'osisRef' && chapterNumStr.contains('.')) {
              chapterNumStr = chapterNumStr.split('.').last;
            }

            currentChapterNum = int.tryParse(chapterNumStr) ?? 1;
          } else if (event.name == 'verse' &&
              currentBookId != null &&
              currentChapterNum != null) {
            // Find verse attributes
            String verseOsisID = '';
            String verseNumStr = '1';

            for (var attr in event.attributes) {
              if (attr.name == 'n') {
                verseNumStr = attr.value;
              } else if (attr.name == 'osisID') {
                verseOsisID = attr.value;
              }
            }

            // Extract verse number from osisID (e.g., "Gen.1.1" -> "1") or use 'n' attribute
            if (verseOsisID.isNotEmpty) {
              final parts = verseOsisID.split('.');
              if (parts.length > 2) {
                verseNumStr = parts[2];
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
          if (event.name == 'verse' && currentVerse != null) {
            verseCount++;
            // Directly yield the verse instead of using a stream controller
            yield currentVerse;
            currentVerse = null;
          }
        } else if (event is XmlTextEvent && currentVerse != null) {
          final trimmedText = event.value.trim();
          if (trimmedText.isNotEmpty) {
            // Append text to current verse
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

      print('XML parsing complete. Total verses yielded: $verseCount');
    } catch (e, stackTrace) {
      print('Error in parseVerses: $e');
      print('Stack trace: $stackTrace');
      rethrow;
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
      print('parseEvents called with content length: ${content.length}');
      print(
          'First 100 chars: ${content.substring(0, content.length > 100 ? 100 : content.length)}');

      // Use a more robust approach for XML parsing
      try {
        // Convert the content to a list of XmlEvents and then create a stream from it
        print('Using XmlEventDecoder to parse XML...');
        final events = XmlEventDecoder().convert(content);
        print('XML parsed successfully, event count: ${events.length}');
        return Stream.fromIterable(events);
      } catch (xmlError, stackTrace) {
        print('XML parsing error: $xmlError');
        print('Stack trace: $stackTrace');

        // Try a fallback approach for web compatibility
        print('Trying fallback XML parsing approach...');
        // Remove XML namespace declarations which can cause issues in some environments
        final cleanedContent =
            content.replaceAll(RegExp(r'xmlns(:\w+)?="[^"]*"'), '');
        final events = XmlEventDecoder().convert(cleanedContent);
        print('Fallback parsing successful, event count: ${events.length}');
        return Stream.fromIterable(events);
      }
    } catch (e, stackTrace) {
      // Handle XML parsing errors with detailed information
      print('Fatal error in parseEvents: $e');
      print('Stack trace: $stackTrace');
      throw ParseError('Failed to parse XML content: $e');
    }
  }

  @override
  Future<String> getContent() async {
    try {
      // For web compatibility, handle the source directly if it's a string
      if (source is String) {
        print('Source is String, returning directly');
        return source as String;
      }

      // Otherwise, try the parent implementation
      try {
        return await super.getContent();
      } catch (e) {
        print('Error in super.getContent(): $e');
        // If the source is a File but we're on web, this will fail
        // In that case, if we can access the source directly, return it
        if (source != null) {
          print('Attempting to return source directly');
          return source.toString();
        }
        rethrow;
      }
    } catch (e) {
      print('Fatal error in getContent: $e');
      throw ParseError('Failed to read content: $e');
    }
  }
}
