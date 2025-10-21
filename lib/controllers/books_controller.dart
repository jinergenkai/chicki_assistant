import 'package:chicki_buddy/core/logger.dart';
import 'package:chicki_buddy/services/book_bridge_service.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:get/get.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import 'package:hive/hive.dart';

class BooksController extends GetxController {
  final RxList<Book> books = <Book>[].obs;
  final RxSet<String> downloadedBooks = <String>{}.obs;
  final RxString downloadingBookId = ''.obs;
  final RxDouble downloadProgress = 0.0.obs;

  final BookService service = BookService();
  final BookBridgeService bookBridgeService = BookBridgeService();


  @override
  void onInit() {
    super.onInit();
    service.init().then((_) async {
      books.value = await bookBridgeService.loadAllBooks();
      print(books);
      // await vocabularyService.importFromBooks(books.value);
      logger.info('Loaded ${books.length} books from service and imported vocabularies to Hive.');
    });
  }

  Future<void> reloadBooks() async {
      books.value = await bookBridgeService.loadAllBooks();
  }

  void downloadBook(String bookId) async {
    downloadingBookId.value = bookId;
    downloadProgress.value = 0.0;
    // Simulate download progress
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      downloadProgress.value = i / 10.0;
    }
    downloadedBooks.add(bookId);
    downloadingBookId.value = '';
    downloadProgress.value = 0.0;
  }

  void removeBook(String bookId) {
    downloadedBooks.remove(bookId);
  }
}
