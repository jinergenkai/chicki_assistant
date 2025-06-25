import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import '../../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            const MoonAvatar(
              avatarSize: MoonAvatarSize.sm,
              showBadge: false,
              content: Icon(Icons.android, size: 18),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = MediaQuery.of(context).size.width * 0.7;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isUser ? context.moonColors!.piccolo : const Color(0xFFeef2f9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        message.content,
                        softWrap: true,
                        style: MoonTypography.typography.body.text14.copyWith(
                          color: isUser ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            const MoonAvatar(
              avatarSize: MoonAvatarSize.sm,
              showBadge: false,
              content: Icon(Icons.person, size: 18),
            ),
        ],
      ),
    );
  }
}