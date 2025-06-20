# Bible Parser Flutter

A Flutter package for parsing Bible texts in various XML formats (USFX, OSIS, ZXBML). This package provides both direct parsing and database-backed approaches for handling Bible data in your Flutter applications. The parser is optimized for production use with proper error handling.

## Features

- Parse Bible texts in multiple formats (USFX, OSIS, ZXBML)
- Automatic format detection
- Memory-efficient SAX-style XML parsing using proper async streams
- Database caching for improved performance
- Search functionality for verses
- Retrieve verses by book and chapter
- Production-ready with proper error handling
- Strong typing with null safety
- Async/await and Stream support

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  bible_parser_flutter: ^0.0.1
```

Then run:

```bash
flutter pub get
```

### Prerequisites

- Flutter SDK
- A Bible XML file in one of the supported formats (USFX, OSIS, ZXBML)

## Usage

### Direct Parsing Approach

Parse a Bible file directly without database caching. This is simpler but less efficient for repeated access:

```dart
import 'dart:io';
import 'package:bible_parser_flutter/bible_parser_flutter.dart';

Future<void> parseBible() async {
  // Create a parser with automatic format detection
  final parser = BibleParser(File('path/to/bible.xml'));
  
  // Access books
  await for (final book in parser.books) {
    print('${book.title} (${book.id})');
    
    // Access chapters and verses
    for (final chapter in book.chapters) {
      for (final verse in chapter.verses) {
        print('${book.id} ${verse.chapterNum}:${verse.num} - ${verse.text}');
      }
    }
  }
  
  // Or access all verses directly
  await for (final verse in parser.verses) {
    print('${verse.bookId} ${verse.chapterNum}:${verse.num} - ${verse.text}');
  }
}
```

### Database Approach (Recommended for Production)

For better performance, especially in production apps, use the database approach:

```dart
import 'package:bible_parser_flutter/bible_parser_flutter.dart';

Future<void> useBibleRepository() async {
  // Create a repository
  final repository = BibleRepository(xmlPath: 'path/to/bible.xml');
  
  // Initialize the database (parses XML and stores in SQLite)
  // This only needs to be done once, typically on first app launch
  await repository.initialize();
  
  // Get all books
  final books = await repository.getBooks();
  for (final book in books) {
    print('${book.title} (${book.id})');
  }
  
  // Get verses from a specific chapter
  final verses = await repository.getVerses('gen', 1);
  for (final verse in verses) {
    print('${verse.bookId} ${verse.chapterNum}:${verse.num} - ${verse.text}');
  }
  
  // Search for verses containing specific text
  final searchResults = await repository.searchVerses('love');
  print('Found ${searchResults.length} verses containing "love"');
  
  // Don't forget to close the database when done
  await repository.close();
}
```

## Performance Considerations

### Direct Parsing

- Simple implementation
- No database setup required
- Always uses the latest source files
- CPU and memory intensive
- Slower initial load times
- Higher battery consumption
- Repeated parsing on each access

### Database Approach

- Much faster access once data is loaded
- Lower memory usage during normal operation
- Better user experience with instant search and navigation
- Reduced battery consumption
- Works offline without re-parsing
- Requires initial setup complexity

## Example

See the `/example` folder for a complete working example of both approaches. The example app demonstrates:

- Parsing Bible files in OSIS, USFX, and ZXBML formats
- Database initialization and querying
- Searching for verses containing specific text
- Browsing verses by book and chapter selection
- Displaying formatted Bible text with proper scrolling

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

Inspired by the Ruby [bible_parser](https://github.com/seven1m/bible_parser) library.
