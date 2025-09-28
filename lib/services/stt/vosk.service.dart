// import 'dart:async';
// import 'package:vosk_flutter_2/vosk_flutter_2.dart';
// import '../stt_service.dart';

// class VoskSTTService implements STTService {
//   final VoskFlutterPlugin vosk = VoskFlutterPlugin.instance();
//   final _resultController = StreamController<String>.broadcast();
//   bool _isListening = false;

//   @override
//   Future<void> initialize() async {
//     // await vosk.init();
//   }

//   @override
//   Future<void> startListening() async {
//     _isListening = true;
//     // vosk.start();
//     // vosk.onResult.listen((VoskResult result) {
//     //   if (result.text != null && result.text!.isNotEmpty) {
//     //     _resultController.add(result.text!);
//     //   }
//     // });
//   }

//   @override
//   Future<void> stopListening() async {
//     _isListening = false;
//     // await vosk.stop();
//   }

//   @override
//   Stream<String> get onResult => _resultController.stream;

//   @override
//   bool get isListening => _isListening;
  
//   @override
//   // TODO: implement onRmsChanged
//   Stream<double> get onRmsChanged => throw UnimplementedError();
  
//   @override
//   // TODO: implement onTextRecognized
//   Stream<String> get onTextRecognized => throw UnimplementedError();
// }