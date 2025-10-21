// import 'package:chicki_buddy/core/logger.dart';
// import 'package:flutter/material.dart';
// import 'package:rive/rive.dart';

// enum ChickyState { wake, loading, error, speech, sleep }

// class ChickyMascotScreen extends StatefulWidget {
//   const ChickyMascotScreen({super.key});

//   @override
//   State<ChickyMascotScreen> createState() => _ChickyMascotScreenState();
// }

// class _ChickyMascotScreenState extends State<ChickyMascotScreen> {
//   File? file;
//   RiveWidgetController? controller;
//   ViewModelInstance? viewModelInstance;

//   late ViewModelInstanceEnum faceStateEnum;

//   @override
//   void initState() {
//     super.initState();
//     _initRive();
//   }

//   Future<void> _initRive() async {
//     // 1️⃣ Load Rive file (Factory.rive là renderer mới)
//     file = await File.asset(
//       'assets/chicky.riv',
//       riveFactory: Factory.rive,
//     );

//     // 2️⃣ Create RiveWidgetController
//     controller = RiveWidgetController(
//       file!,
//       artboardSelector: ArtboardSelector.byName('Artboard'),
//       stateMachineSelector: StateMachineSelector.byName('ChickyMachine'),
//     );

//     // 3️⃣ Bind data automatically to ViewModel
//     viewModelInstance = controller!.dataBind(DataBind.auto());

//     // 4️⃣ Debug: xem ViewModel có gì
//     logger.info('ViewModel properties: ${viewModelInstance!.properties}');

//     // 5️⃣ Lấy biến enum từ ViewModel
//     faceStateEnum = viewModelInstance!.enumerator('CurrentState')!;
//     // dynamic state = viewModelInstance!.('CurrentState')!;
//     // logger.info('State enum: $state');
//     faceStateEnum.addListener((String? value) {
//       print(value);
//       logger.info('Face state changed: ${faceStateEnum.value}');
//     });

//     // 6️⃣ Set enum value theo string trong Rive (ví dụ: wake / sleep / smile)
//     // faceStateEnum.value = 'wake';

//     // 7️⃣ In ra để debug
//     logger.info('Face current state: ${faceStateEnum.value}');

//     setState(() {});
//   }

//   @override
//   void dispose() {
//     faceStateEnum.dispose();
//     viewModelInstance?.dispose();
//     controller?.dispose();
//     file?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final controller = this.controller;
//     if (controller == null) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Column(
//         children: [
//           Expanded(
//             child: Center(
//               child: RiveWidget(
//                 controller: controller,
//                 // fit: BoxFit.contain,
//                 layoutScaleFactor: 1.0,
//               ),
//             ),
//           ),
//           const SizedBox(height: 32),
//           Wrap(
//             spacing: 12,
//             children: ChickyState.values.map((state) {
//               return ElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     faceStateEnum.value = state.name;
//                     logger.info('Changed state to: ${state.name}');
//                   });
//                 },
//                 child: Text(state.name),
//               );
//             }).toList(),
//           ),
//           const SizedBox(height: 32),
//         ],
//       ),
//     );
//   }
// }
