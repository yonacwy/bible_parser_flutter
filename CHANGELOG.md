## 0.1.0 - Initial Release

### Features
* Support for multiple Bible XML formats:
  * OSIS (Open Scripture Information Standard)
  * USFX (Unified Scripture Format XML)
  * ZXBML (Zefania XML Bible Markup Language)
* Automatic format detection
* Memory-efficient XML parsing using proper async streams
* Production-ready with proper error handling and no debug statements

### Bible Repository Features
* SQLite database caching for improved performance
* Methods to retrieve books, chapters, and verses
* Verse retrieval by book and chapter
* Text search functionality across verses

### Example App
* Demonstrates both direct parsing and database approaches
* UI for selecting between different Bible formats
* Book and chapter selection interface
* Verse display with proper formatting and scrolling
* Search functionality for finding verses containing specific text
