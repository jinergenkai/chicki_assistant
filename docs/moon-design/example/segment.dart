import 'package:example/src/storybook/common/widgets/text_divider.dart';
import 'package:flutter/material.dart';

class IconsSegment extends StatelessWidget {
  final Map<String, IconData> segmentMap;

  const IconsSegment({
    super.key,
    required this.segmentMap,
  });

  @override
  Widget build(BuildContext context) {
    String createSegmentTitle(String text) {
      final String title = text.split('_').first;
      return title[0].toUpperCase() + title.substring(1);
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 16),
            sliver: SliverToBoxAdapter(
              child: TextDivider(
                text: createSegmentTitle(segmentMap.keys.first),
                paddingBottom: 0,
              ),
            ),
          ),
          SliverGrid.builder(
            itemCount: segmentMap.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              mainAxisExtent: 104,
            ),
            itemBuilder: (BuildContext context, int index) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (segmentMap.keys.toList()[index].contains("16"))
                    Icon(segmentMap.values.toList()[index], size: 16)
                  else if (segmentMap.keys.toList()[index].contains("24"))
                    Icon(segmentMap.values.toList()[index], size: 24)
                  else
                    Icon(segmentMap.values.toList()[index], size: 32),
                  const SizedBox(height: 16),
                  Text(
                    segmentMap.keys.toList()[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              );
            },
          ),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 16),
          ),
        ],
      ),
    );
  }
}
