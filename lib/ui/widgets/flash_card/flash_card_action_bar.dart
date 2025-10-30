import 'dart:ui';
import 'package:flutter/material.dart';

class FlashCardActionBar extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onFlip;
  final VoidCallback onNext;
  final bool isFlipped;
  final VoidCallback? onTextToSpeech;
  final VoidCallback? onFavorite;
  final VoidCallback? onEdit;
  final VoidCallback? onAddNote;
  final bool isFavorite;

  const FlashCardActionBar({
    super.key,
    required this.onPrevious,
    required this.onFlip,
    required this.onNext,
    required this.isFlipped,
    this.onTextToSpeech,
    this.onFavorite,
    this.onEdit,
    this.onAddNote,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ActionButton(
            icon: Icons.skip_previous_rounded,
            onPressed: onPrevious,
            color: Colors.orange.shade400,
            tooltip: 'Previous',
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: isFlipped ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            onPressed: onFlip,
            color: Colors.blue.shade500,
            tooltip: 'Flip card',
            isPrimary: true,
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.skip_next_rounded,
            onPressed: onNext,
            color: Colors.green.shade400,
            tooltip: 'Next',
          ),
          const SizedBox(width: 4),
          _buildDivider(),
          const SizedBox(width: 4),
          _OverflowMenuButton(
            onTextToSpeech: onTextToSpeech,
            onFavorite: onFavorite,
            onEdit: onEdit,
            onAddNote: onAddNote,
            isFavorite: isFavorite,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 32,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade300.withOpacity(0),
            Colors.grey.shade400,
            Colors.grey.shade300.withOpacity(0),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final String tooltip;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    required this.tooltip,
    this.isPrimary = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isPrimary ? 56.0 : 48.0;

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
          widget.onPressed();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color,
                      widget.color.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(widget.isPrimary ? 18 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(_isPressed ? 0.4 : 0.3),
                      blurRadius: _isPressed ? 8 : 12,
                      offset: Offset(0, _isPressed ? 2 : 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: widget.isPrimary ? 28 : 24,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OverflowMenuButton extends StatelessWidget {
  final VoidCallback? onTextToSpeech;
  final VoidCallback? onFavorite;
  final VoidCallback? onEdit;
  final VoidCallback? onAddNote;
  final bool isFavorite;

  const _OverflowMenuButton({
    this.onTextToSpeech,
    this.onFavorite,
    this.onEdit,
    this.onAddNote,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          color: Colors.grey.shade700,
          size: 24,
        ),
      ),
      offset: const Offset(0, -8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      color: Colors.white,
      itemBuilder: (context) => [
        if (onTextToSpeech != null)
          _buildMenuItem(
            value: 'tts',
            icon: Icons.volume_up_rounded,
            label: 'Text to Speech',
            color: Colors.purple.shade400,
          ),
        if (onFavorite != null)
          _buildMenuItem(
            value: 'favorite',
            icon: isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
            label: isFavorite ? 'Unfavorite' : 'Add to Favorite',
            color: Colors.amber.shade600,
          ),
        if (onEdit != null)
          _buildMenuItem(
            value: 'edit',
            icon: Icons.edit_rounded,
            label: 'Edit Vocabulary',
            color: Colors.blue.shade500,
          ),
        if (onAddNote != null)
          _buildMenuItem(
            value: 'note',
            icon: Icons.note_add_rounded,
            label: 'Add Note',
            color: Colors.teal.shade400,
          ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'tts':
            onTextToSpeech?.call();
            break;
          case 'favorite':
            onFavorite?.call();
            break;
          case 'edit':
            onEdit?.call();
            break;
          case 'note':
            onAddNote?.call();
            break;
        }
      },
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 56,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
