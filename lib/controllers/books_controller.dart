import 'package:chicki_buddy/core/logger.dart';
import 'package:get/get.dart';

class BooksController extends GetxController {
  // Example book list (simulate remote dictionaries)
  final books = [
    {
      'id': 'oxford_3000',
      'title': 'Oxford 3000',
      'desc': 'Essential English words for learners.',
    },
    {
      'id': 'oxford_5000',
      'title': 'Oxford 5000',
      'desc': 'Advanced English vocabulary.',
    },
    {
      'id': 'awl',
      'title': 'Academic Word List',
      'desc': 'Words for academic English.',
    },
    {
      'id': 'ielts_cambridge',
      'title': 'IELTS Cambridge',
      'desc': 'IELTS exam vocabulary.',
    },
    {
      'id': 'ielts_cambridge1',
      'title': 'IELTS Cambridge',
      'desc': 'IELTS exam vocabulary.',
    },
    {
      'id': 'ielts_cambridge2',
      'title': 'IELTS Cambridge',
      'desc': 'IELTS exam vocabulary.',
    },
  ].obs;

  // Download state
  final downloadingBookId = RxString('');
  final downloadedBooks = <String>{}.obs;
  final downloadProgress = 0.0.obs;

  // Simulate download with progress
  void downloadBook(String bookId) async {
    logger.info('Starting download for book: $bookId');
    // if (downloadingBookId.value.isNotEmpty) return;
    downloadingBookId.value = bookId;
    downloadProgress.value = 0;
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      downloadProgress.value = (i * 10) / 100;
      print('Progress: ${downloadProgress.value}, Downloading: ${downloadingBookId.value}');
    }
    downloadedBooks.add(bookId);
    print('Downloaded books: $downloadedBooks');
    downloadingBookId.value = '';
    downloadProgress.value = 0;
    print('Download finished, Downloading: ${downloadingBookId.value}');
    // Simulate sync logic here if needed
    await Future.delayed(const Duration(seconds: 2));
  }

  void removeBook(String bookId) {
    // Simulate removing cached/downloaded files for this book
    downloadedBooks.remove(bookId);
    downloadedBooks.refresh();
  }
}
