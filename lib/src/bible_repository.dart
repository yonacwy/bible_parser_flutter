import 'dart:async';
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'bible_parser.dart';
import 'book.dart';
import 'verse.dart';

/// Repository for accessing Bible data with database caching.
class BibleRepository {
  /// The database instance.
  late Database _database;
  
  /// The path to the XML file.
  final String xmlPath;
  
  /// The XML content as a string (used when loading from assets in web).
  final String? xmlString;
  
  /// The format of the Bible data.
  final String? format;
  
  /// Creates a new Bible repository from a file path.
  BibleRepository({
    required this.xmlPath,
    this.format,
  }) : xmlString = null;
  
  /// Creates a new Bible repository from XML content as a string.
  /// 
  /// This is useful for web applications where direct file access is not available.
  BibleRepository.fromString({
    required this.xmlString,
    this.format,
  }) : xmlPath = '';
  
  /// Initializes the repository.
  /// 
  /// This will create the database if it doesn't exist, or open it if it does.
  Future<bool> initialize() async {
    try {
      // Check if database exists and is current version
      final dbInitialized = await _isDatabaseInitialized();
      
      if (!dbInitialized) {
        // Create database from XML
        await _createDatabaseFromXml();
      }
      
      // Open database connection
      _database = await _openDatabase();
      
      return true;
    } catch (e, stackTrace) {
      throw Exception('Failed to initialize Bible repository: $e, $stackTrace');
    }
  }
  
  /// Checks if the database is initialized.
  Future<bool> _isDatabaseInitialized() async {
    final dbPath = await _getDatabasePath();
    final dbFile = File(dbPath);
    
    /*
    // For testing purposes, always return false to force database recreation
    
    // Delete existing database if it exists
    if (dbFile.existsSync()) {
      try {
        await dbFile.delete();
      } catch (e) {
        // Silently continue if deletion fails
        print('Failed to delete database file: $e');
      }
    }
    
    return false;
   */ 
    // For production implementation
    if (!dbFile.existsSync()) {
      return false;
    }
    
    // Check if database is current version
    final db = await openDatabase(dbPath);
    try {
      final version = await db.getVersion();
      await db.close();
      return version == 1;
    } catch (e) {
      await db.close();
      return false;
    }    
  }
  
  /// Creates the database from the XML file or string.
  Future<void> _createDatabaseFromXml() async {
    // Parse XML from file or string
    final BibleParser parser;
    if (xmlString != null) {
      // Use the XML string directly
      parser = BibleParser.fromString(xmlString!, format: format);
    } else {
      // Use the file path
      parser = BibleParser(File(xmlPath), format: format);
    }
    
    // Create database schema
    final db = await _openDatabase();
    
    try {
      // Create tables
      await db.execute('''
        CREATE TABLE books (
          id TEXT PRIMARY KEY,
          num INTEGER,
          title TEXT
        )
      ''');
      
      await db.execute('''
        CREATE TABLE verses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          book_id TEXT,
          chapter_num INTEGER,
          verse_num INTEGER,
          text TEXT,
          FOREIGN KEY (book_id) REFERENCES books (id)
        )
      ''');
      
      // Create indexes for fast lookup
      await db.execute('CREATE INDEX idx_verses_lookup ON verses (book_id, chapter_num, verse_num)');
      await db.execute('CREATE INDEX idx_verses_search ON verses (text)');
      
      // Insert data in batches
      await db.transaction((txn) async {
        try {
          // Process books
          await for (final book in parser.books) {
            // Insert book
            await txn.insert('books', book.toMap());
            
            // Process verses for this book
            if (book.verses.isNotEmpty) {
              for (final verse in book.verses) {
                await txn.insert('verses', verse.toMap());
              }
            }
          }
        } catch (e, stackTrace) {
          throw Exception('Failed to process Bible data: $e, $stackTrace');
        }
      });
    } catch (e, stackTrace) {
      throw Exception('Failed to create Bible database: $e, $stackTrace');
    }
    
    // Set database version
    await db.setVersion(1);
    await db.close();
  }
  
  /// Opens the database.
  Future<Database> _openDatabase() async {
    return openDatabase(
      await _getDatabasePath(),
      version: 1,
      onCreate: (db, version) async {
        // This is handled by _createDatabaseFromXml
      },
    );
  }
  
  /// Gets the database name from the XML path.
  String _getDatabaseName(String xmlPath, String defaultName) {
    if (xmlPath.isNotEmpty) {
      // Get the filename without extension from xmlPath
      final fileName = basename(xmlPath);
      final nameWithoutExtension = fileName.split('.').first;
      
      // Sanitize the filename by removing improper characters
      // Replace characters that are not alphanumeric, underscore, or hyphen with underscore
      final sanitizedName = nameWithoutExtension.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      
      return '$sanitizedName.db';
    } else {
      // Fallback for when using xmlString (no path)
      return defaultName;
    }
  }

  /// Gets the path to the database file.
  Future<String> _getDatabasePath() async {
    try {
      // Use temporary directory for testing to avoid permission issues
      final tempDirectory = await getTemporaryDirectory();
      return join(tempDirectory.path, _getDatabaseName(xmlPath, 'bible_test.db'));
    } catch (e) {
      // Fall back to documents directory
      final documentsDirectory = await getApplicationDocumentsDirectory();
      return join(documentsDirectory.path, _getDatabaseName(xmlPath, 'bible.db'));
    }
  }
  
  /// Gets all books in the Bible.
  Future<List<Book>> getBooks() async {
    final maps = await _database.query('books', orderBy: 'num');
    return maps.map((map) => Book.fromMap(map)).toList();
  }
  
  /// Gets the number of chapters in a book.
  Future<int> getChapterCount(String bookId) async {
    final result = await _database.rawQuery(
      'SELECT COUNT(DISTINCT chapter_num) as count FROM verses WHERE book_id = ?',
      [bookId]
    );
    return result.first['count'] as int;
  }
  
  /// Gets all verses in a chapter.
  Future<List<Verse>> getVerses(String bookId, int chapterNum) async {
    final maps = await _database.query(
      'verses',
      where: 'book_id = ? AND chapter_num = ?',
      whereArgs: [bookId, chapterNum],
      orderBy: 'verse_num'
    );
    return maps.map((map) => Verse.fromMap(map)).toList();
  }
  
  /// Searches for verses containing the given query.
  Future<List<Verse>> searchVerses(String query) async {
    final maps = await _database.query(
      'verses',
      where: 'text LIKE ?',
      whereArgs: ['%$query%'],
      limit: 100
    );
    return maps.map((map) => Verse.fromMap(map)).toList();
  }
  
  /// Gets a specific verse.
  Future<Verse?> getVerse(String bookId, int chapterNum, int verseNum) async {
    final maps = await _database.query(
      'verses',
      where: 'book_id = ? AND chapter_num = ? AND verse_num = ?',
      whereArgs: [bookId, chapterNum, verseNum],
      limit: 1
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return Verse.fromMap(maps.first);
  }
  
  /// Closes the database connection.
  Future<void> close() async {
    await _database.close();
  }
}
