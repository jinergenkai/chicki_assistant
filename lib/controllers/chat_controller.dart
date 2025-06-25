import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/message.dart';

class ChatController extends GetxController {
  static const String boxName = 'messagesBox';
  late Box<Message> _box;
  final RxList<Message> messages = <Message>[].obs;

  @override
  void onInit() async {
    super.onInit();
    await _initHive();
  }

  Future<void> _initHive() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MessageAdapter());
    }
    _box = await Hive.openBox<Message>(boxName);
    messages.assignAll(_box.values);
  }

  void addMessage(Message message) {
    // Không thêm nếu message giống message cuối cùng (tránh duplicate liên tiếp)
    // if (messages.isNotEmpty && messages.last.content == message.content && messages.last.isUser == message.isUser) {
    //   return;
    // }
    messages.add(message);
    _box.add(message);
  }

  void clearMessages() async {
    await _box.clear();
    messages.clear();
  }
}