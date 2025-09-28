import 'package:chicki_buddy/models/super_action.dart';

class SuperActionService {
  final List<SuperAction> actions = [];

  void registerAction(SuperAction action) {
    actions.add(action);
  }

  Future<void> runAction(String id) async {
    final action = actions.firstWhere((a) => a.id == id);
    if (action.action != null) {
      await action.action!();
    }
  }
}
