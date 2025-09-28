import 'package:chicki_buddy/models/vocabulary.dart';
import 'package:chicki_buddy/services/vocabulary.service.dart';
import 'package:get/get.dart';

class VocabularyController extends GetxController {
  final VocabularyService service = VocabularyService();

  RxList<Vocabulary> vocabList = <Vocabulary>[].obs;

  @override
  void onInit() {
    super.onInit();
    service.init().then((_) {
      vocabList.value = service.getAll();
    });
  }

  void addVocabulary(Vocabulary vocab) async {
    await service.upsertVocabulary(vocab);
    vocabList.value = service.getAll();
  }
}
