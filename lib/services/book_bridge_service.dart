import 'dart:async';
// Dart

import 'package:chicki_buddy/core/app_event_bus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:chicki_buddy/models/book.dart';

/// Bridge service để giao tiếp với foreground isolate cho các thao tác book.
/// Gửi request qua FlutterForegroundTask, nhận kết quả qua callback/future.
class BookBridgeService {
  /// Lấy danh sách book từ foreground isolate
  Future<List<Book>> loadAllBooks() async {
    final completer = Completer<List<Book>>();
    FlutterForegroundTask.sendDataToTask({'bridge': 'book', 'action': 'listBook'});
    // Lắng nghe eventBus để nhận kết quả trả về từ foreground isolate
    late StreamSubscription sub;
    sub = eventBus.stream.where((event) => event.type == AppEventType.bookBridgeResult).listen((event) {
      if (event.payload is List) {
        final books = (event.payload as List).map((e) => Book.fromJson(Map<String, dynamic>.from(e))).toList();
        completer.complete(books);
        sub.cancel();
      }
    });
    return completer.future;
  }

  /// Tải book qua foreground isolate
  Future<void> downloadBook(String bookId) async {
    FlutterForegroundTask.sendDataToTask({'bridge': 'book', 'action': 'downloadBook', 'bookId': bookId});
    // TODO: Lắng nghe kết quả trả về nếu cần
  }

  /// Xóa book qua foreground isolate
  Future<void> removeBook(String bookId) async {
    FlutterForegroundTask.sendDataToTask({'bridge': 'book', 'action': 'removeBook', 'bookId': bookId});
    // TODO: Lắng nghe kết quả trả về nếu cần
  }
}
