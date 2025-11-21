import 'package:flutter/material.dart';

class SRSReviewButtons extends StatefulWidget {
  final Function(int quality) onQualitySelected;
  final bool isVisible;

  const SRSReviewButtons({
    super.key,
    required this.onQualitySelected,
    this.isVisible = true,
  });

  @override
  State<SRSReviewButtons> createState() => _SRSReviewButtonsState();
}

class _SRSReviewButtonsState extends State<SRSReviewButtons>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int? _hoveredQuality;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SRSReviewButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.forward();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getQualityLabel(int quality) {
    switch (quality) {
      case 0:
        return 'Again';
      case 1:
        return 'Hard';
      case 2:
        return 'Medium';
      case 3:
        return 'Good';
      case 4:
        return 'Easy';
      case 5:
        return 'Perfect';
      default:
        return '';
    }
  }

  String _getQualityEmoji(int quality) {
    switch (quality) {
      case 0:
        return '😫';
      case 1:
        return '😰';
      case 2:
        return '🤔';
      case 3:
        return '😊';
      case 4:
        return '😄';
      case 5:
        return '🤩';
      default:
        return '';
    }
  }

  Color _getQualityColor(int quality) {
    switch (quality) {
      case 0:
        return Colors.red.shade400;
      case 1:
        return Colors.orange.shade400;
      case 2:
        return Colors.yellow.shade600;
      case 3:
        return Colors.lightGreen.shade400;
      case 4:
        return Colors.green.shade500;
      case 5:
        return Colors.blue.shade500;
      default:
        return Colors.grey;
    }
  }

  String _getNextReviewPreview(int quality) {
    // Simple preview based on quality
    switch (quality) {
      case 0:
      case 1:
        return 'Review: Tomorrow';
      case 2:
        return 'Review: In 2 days';
      case 3:
        return 'Review: In 3 days';
      case 4:
        return 'Review: In 6 days';
      case 5:
        return 'Review: In 10 days';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'How well did you know this?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quality buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildQualityButton(index),
              );
            }),
          ),

          // Preview next review
          if (_hoveredQuality != null) ...[
            const SizedBox(height: 12),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _hoveredQuality != null ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      _getNextReviewPreview(_hoveredQuality!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQualityButton(int quality) {
    final isHovered = _hoveredQuality == quality;
    final color = _getQualityColor(quality);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredQuality = quality),
      onExit: (_) => setState(() => _hoveredQuality = null),
      child: GestureDetector(
        onTap: () => widget.onQualitySelected(quality),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isHovered ? 56 : 48,
          height: isHovered ? 56 : 48,
          decoration: BoxDecoration(
            color: isHovered ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color,
              width: isHovered ? 3 : 2,
            ),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getQualityEmoji(quality),
                style: TextStyle(fontSize: isHovered ? 22 : 18),
              ),
              const SizedBox(height: 2),
              Text(
                quality.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isHovered ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
