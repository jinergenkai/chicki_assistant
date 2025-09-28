import 'package:chicki_buddy/models/voice_note.dart';
import 'package:hive/hive.dart';

class VoiceNoteService {
  static const String boxName = 'voiceNoteBox';
  late Box<VoiceNote> _box;

  Future<void> init() async {
    _box = await Hive.openBox<VoiceNote>(boxName);
  }

  Future<void> addNote(VoiceNote note) async {
    final key = await _box.add(note);
    note.id = key as int?;
    await _box.put(key, note);
  }

  List<VoiceNote> getAll({bool includeDeleted = false}) {
    final all = _box.values.toList();
    if (!includeDeleted) return all.where((n) => !n.isDeleted).toList();
    return all;
  }

  Future<void> markDeleted(VoiceNote note) async {
    note.isDeleted = true;
    note.isSync = false;
    await _box.put(note.id, note);
  }
}
