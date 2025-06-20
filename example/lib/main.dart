import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:bible_parser_flutter/bible_parser_flutter.dart';
import 'package:xml/xml_events.dart';

/// Enum for Bible formats supported by the app
enum BibleFormat {
  osis,
  usfx,
  zxbml
}

void main() {
  runApp(const BibleParserExampleApp());
}

class BibleParserExampleApp extends StatelessWidget {
  const BibleParserExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible Parser Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const BibleParserExampleScreen(),
    );
  }
}

class BibleParserExampleScreen extends StatefulWidget {
  const BibleParserExampleScreen({super.key});

  @override
  State<BibleParserExampleScreen> createState() => _BibleParserExampleScreenState();
}

class _BibleParserExampleScreenState extends State<BibleParserExampleScreen> {
  String xmlPath = 'assets/bible_small.xml'; // Default to OSIS format
  BibleFormat currentFormat = BibleFormat.osis;
  bool isLoading = false;
  String result = '';
  BibleRepository? repository;
  
  // For verse viewing feature
  List<Book> books = [];
  Book? selectedBook;
  int? selectedChapter;
  List<int> availableChapters = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Parser Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format selection
            Text('Select Bible Format:', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                Radio<BibleFormat>(
                  value: BibleFormat.osis,
                  groupValue: currentFormat,
                  onChanged: (BibleFormat? value) {
                    setState(() {
                      currentFormat = value!;
                      xmlPath = 'assets/bible_small.xml';
                      result = 'Selected OSIS format';
                    });
                  },
                ),
                const Text('OSIS'),
                const SizedBox(width: 20),
                Radio<BibleFormat>(
                  value: BibleFormat.usfx,
                  groupValue: currentFormat,
                  onChanged: (BibleFormat? value) {
                    setState(() {
                      currentFormat = value!;
                      xmlPath = 'assets/bible_small_usfx.xml';
                      result = 'Selected USFX format';
                    });
                  },
                ),
                const Text('USFX'),
                const SizedBox(width: 20),
                Radio<BibleFormat>(
                  value: BibleFormat.zxbml,
                  groupValue: currentFormat,
                  onChanged: (BibleFormat? value) {
                    setState(() {
                      currentFormat = value!;
                      xmlPath = 'assets/bible_small_zxbml.xml';
                      result = 'Selected ZXBML format';
                    });
                  },
                ),
                const Text('ZXBML'),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _parseDirectly,
              child: const Text('Parse Directly'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _initializeDatabase,
              child: const Text('Initialize Database'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: repository != null ? _searchVerses : null,
              child: const Text('Search for "love"'),
            ),
            const SizedBox(height: 20),
            
            // Book and Chapter selection
            if (repository != null) ...[  
              Text('View Verses by Book and Chapter:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Book dropdown
                  Expanded(
                    child: DropdownButtonFormField<Book>(
                      decoration: const InputDecoration(
                        labelText: 'Select Book',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedBook,
                      items: books.map((book) {
                        return DropdownMenuItem<Book>(
                          value: book,
                          child: Text('${book.num}. ${book.title}'),
                        );
                      }).toList(),
                      onChanged: (Book? book) {
                        setState(() {
                          selectedBook = book;
                          selectedChapter = null;
                          _updateAvailableChapters();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Chapter dropdown
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Select Chapter',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedChapter,
                      items: availableChapters.map((chapter) {
                        return DropdownMenuItem<int>(
                          value: chapter,
                          child: Text('Chapter $chapter'),
                        );
                      }).toList(),
                      onChanged: selectedBook == null ? null : (int? chapter) {
                        setState(() {
                          selectedChapter = chapter;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: (selectedBook != null && selectedChapter != null) ? _loadVerses : null,
                child: const Text('Load Verses'),
              ),
            ],
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SelectableText(
                      result,
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Test the original parser with our fix
  Future<void> _parseDirectly() async {
    setState(() {
      isLoading = true;
      result = 'Testing parser...';
    });
    
    try {
      // Load the XML content from assets
      final xmlString = await DefaultAssetBundle.of(context).loadString(xmlPath);
      
      // Create the original parser with the XML string
      final parser = BibleParser.fromString(xmlString, format: currentFormat.name.toUpperCase());
      
      // Set up a timeout
      bool timedOut = false;
      final timeout = Timer(Duration(seconds: 30), () {
        print('Parsing timed out after 30 seconds');
        timedOut = true;
        if (!mounted) return;
        setState(() {
          result += '\n\nParsing timed out after 30 seconds. There may be an issue with the parser.';
          isLoading = false;
        });
      });
      
      // Collect verses from the parser
      final verses = <Verse>[];
      int count = 0;
      bool receivedFirstVerse = false;
      
      final subscription = parser.verses.listen(
        (verse) {
          verses.add(verse);
          count++;
          
          if (count % 5 == 0 && mounted) {
            setState(() {
              result = 'Parsing...\n\nParsed ${verses.length} verses so far';
            });
          }
        },
        onError: (e) {},
        onDone: () {},
      );
      
      // Wait for parsing to complete or timeout
      await Future.delayed(Duration(seconds: 20));
      subscription.cancel();
      timeout.cancel();
      
      if (!timedOut && mounted) {
        if (verses.isEmpty) {
          setState(() {
            result = 'Parser: No verses were parsed.';
            isLoading = false;
          });
        } else {
          setState(() {
            result = 'Parser Results (${verses.length} verses):\n\n' +
                verses.map((v) => '${v.bookId} ${v.chapterNum}:${v.num} - ${v.text}').join('\n\n');
            isLoading = false;
          });
        }
      }
    } catch (e, stackTrace) {
      
      if (mounted) {
        setState(() {
          result = 'Parser error: ${e.toString()}\n\nStack trace:\n$stackTrace';
          isLoading = false;
        });
      }
    }
  }

  // Example of database approach
  Future<void> _initializeDatabase() async {
    setState(() {
      isLoading = true;
      result = '';
    });

    try {
      // Load the XML content from assets (works on all platforms including web)
      final xmlString = await DefaultAssetBundle.of(context).loadString(xmlPath);
      
      // Create a repository with the XML string and selected format
      repository = BibleRepository.fromString(
        xmlString: xmlString,
        format: currentFormat.name.toUpperCase()
      );
      
      // Initialize the database (this will parse the XML and store it in the database)
      final stopwatch = Stopwatch()..start();
      await repository!.initialize();
      stopwatch.stop();
      
      // Get all books
      books = await repository!.getBooks();
      if (books.isNotEmpty) {
        selectedBook = books.first;
        _updateAvailableChapters();
      }
      
      setState(() {
        result = 'Database Initialized in ${stopwatch.elapsedMilliseconds}ms\n\n' +
            'Books:\n' +
            books.map((b) => '${b.num}. ${b.title} (${b.id})').join('\n');
      });
    } catch (e) {
      setState(() {
        result = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Example of searching verses using the database
  Future<void> _searchVerses() async {
    if (repository == null) return;
    
    setState(() {
      isLoading = true;
      result = '';
    });

    try {
      // Search for verses containing "love"
      final stopwatch = Stopwatch()..start();
      final verses = await repository!.searchVerses('love');
      stopwatch.stop();
      
      setState(() {
        result = 'Search completed in ${stopwatch.elapsedMilliseconds}ms\n\n' +
            'Found ${verses.length} verses containing "love":\n\n' +
            verses.take(10).map((v) => '${v.bookId} ${v.chapterNum}:${v.num} - ${v.text}').join('\n\n') +
            (verses.length > 10 ? '\n\n... and ${verses.length - 10} more' : '');
      });
    } catch (e) {
      setState(() {
        result = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  // Update the available chapters based on the selected book
  Future<void> _updateAvailableChapters() async {
    if (repository == null || selectedBook == null) return;
    
    try {
      final chapterCount = await repository!.getChapterCount(selectedBook!.id);
      setState(() {
        availableChapters = List.generate(chapterCount, (i) => i + 1);
        if (availableChapters.isNotEmpty) {
          selectedChapter = 1; // Default to first chapter
        } else {
          selectedChapter = null;
        }
      });
    } catch (e) {
      setState(() {
        availableChapters = [];
        selectedChapter = null;
        result = 'Error loading chapters: ${e.toString()}';
      });
    }
  }
  
  // Load verses for the selected book and chapter
  Future<void> _loadVerses() async {
    if (repository == null || selectedBook == null || selectedChapter == null) return;
    
    setState(() {
      isLoading = true;
      result = '';
    });

    try {
      final stopwatch = Stopwatch()..start();
      final verses = await repository!.getVerses(selectedBook!.id, selectedChapter!);
      stopwatch.stop();
      
      setState(() {
        result = '${selectedBook!.title} Chapter $selectedChapter\n' +
            'Loaded ${verses.length} verses in ${stopwatch.elapsedMilliseconds}ms\n\n' +
            verses.map((v) => 'Verse ${v.num}: ${v.text}').join('\n\n');
      });
    } catch (e) {
      setState(() {
        result = 'Error loading verses: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
