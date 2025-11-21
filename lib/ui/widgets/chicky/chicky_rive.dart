import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

enum ChickyState { wake, loading, error, speech, sleep }

class ChickyRive extends StatefulWidget {
  final ChickyState state;
  final double size;

  const ChickyRive({super.key, required this.state, this.size = 40});

  @override
  State<ChickyRive> createState() => _ChickyRiveState();
}

class _ChickyRiveState extends State<ChickyRive> {
  static RiveWidgetController? _controller;
  static ViewModelInstanceEnum? _faceStateEnum;
  static bool _isInitialized = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    if (_isInitialized && _controller != null && _faceStateEnum != null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final file = await File.asset(
        'assets/chicky.riv',
        riveFactory: Factory.rive,
      );
      _controller = RiveWidgetController(
        file!,
        artboardSelector: ArtboardSelector.byName('Artboard'),
        stateMachineSelector: StateMachineSelector.byName('ChickyMachine'),
      );
      final viewModelInstance = _controller!.dataBind(DataBind.auto());
      _faceStateEnum = viewModelInstance.enumerator('CurrentState')!;
      _isInitialized = true;
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error initializing ChickyRive: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void didUpdateWidget(ChickyRive oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chỉ cập nhật state nếu đã khởi tạo và state thay đổi
    if (_isInitialized &&
        _faceStateEnum != null &&
        oldWidget.state != widget.state) {
      _faceStateEnum!.value = widget.state.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _controller == null || _faceStateEnum == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Cập nhật state hiện tại
    if (_faceStateEnum!.value != widget.state.name) {
      _faceStateEnum!.value = widget.state.name;
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RiveWidget(
        controller: _controller!,
        layoutScaleFactor: 1.0,
      ),
    );
  }
}