import 'package:chicki_buddy/core/logger.dart';

/// Utility class for fuzzy text matching and number conversion
class TextMatcher {
  /// Map of text numbers to integers (including common SST errors)
  static const Map<String, int> _textToNumber = {
    // Standard text numbers
    'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4,
    'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,

    // Common SST misrecognitions
    'won': 1, 'want': 1, 'to': 2, 'too': 2, 'for': 4, 'fore': 4,
    'ate': 8, 'tin': 10, 'teen': 10,

    // Alternative spellings
    'first': 1, 'second': 2, 'third': 3, 'forth': 4, 'fourth': 4,
    'fifth': 5, 'sixth': 6, 'seventh': 7, 'eighth': 8, 'ninth': 9, 'tenth': 10,
  };

  /// Extract number from text input
  /// Handles: "1", "one", "select one", "number two", "choose too", etc.
  static int? extractNumber(String input) {
    final normalized = input.toLowerCase().trim();

    // Try direct number parse first
    final directNumber = int.tryParse(normalized);
    if (directNumber != null) return directNumber;

    // Check each word in the input
    final words = normalized.split(RegExp(r'\s+'));
    for (final word in words) {
      // Check text-to-number map
      if (_textToNumber.containsKey(word)) {
        return _textToNumber[word];
      }

      // Try parsing as number
      final num = int.tryParse(word);
      if (num != null) return num;
    }

    return null;
  }

  /// Calculate similarity score between two strings (0.0 to 1.0)
  /// Uses Jaro-Winkler distance for better phonetic matching
  static double similarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final str1 = s1.toLowerCase();
    final str2 = s2.toLowerCase();

    // Jaro distance
    final jaroScore = _jaroDistance(str1, str2);

    // Jaro-Winkler bonus for common prefix
    int prefixLength = 0;
    for (int i = 0; i < str1.length.coerceAtMost(str2.length); i++) {
      if (str1[i] == str2[i]) {
        prefixLength++;
      } else {
        break;
      }
    }
    prefixLength = prefixLength.coerceAtMost(4); // Max prefix bonus of 4 chars

    return jaroScore + (prefixLength * 0.1 * (1.0 - jaroScore));
  }

  /// Calculate Jaro distance between two strings
  static double _jaroDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;

    if (len1 == 0 && len2 == 0) return 1.0;
    if (len1 == 0 || len2 == 0) return 0.0;

    final matchDistance = (len1.coerceAtLeast(len2) / 2 - 1).toInt();
    final s1Matches = List.filled(len1, false);
    final s2Matches = List.filled(len2, false);

    int matches = 0;
    int transpositions = 0;

    // Find matches
    for (int i = 0; i < len1; i++) {
      final start = (i - matchDistance).coerceAtLeast(0);
      final end = (i + matchDistance + 1).coerceAtMost(len2);

      for (int j = start; j < end; j++) {
        if (s2Matches[j] || s1[i] != s2[j]) continue;
        s1Matches[i] = true;
        s2Matches[j] = true;
        matches++;
        break;
      }
    }

    if (matches == 0) return 0.0;

    // Count transpositions
    int k = 0;
    for (int i = 0; i < len1; i++) {
      if (!s1Matches[i]) continue;
      while (!s2Matches[k]) k++;
      if (s1[i] != s2[k]) transpositions++;
      k++;
    }

    return (matches / len1 + matches / len2 + (matches - transpositions / 2) / matches) / 3.0;
  }

  /// Find best matching item from a list
  /// Returns tuple: (index, item, score)
  static ({int index, dynamic item, double score})? findBestMatch(
    String query,
    List<dynamic> items,
    String Function(dynamic) getSearchText,
  ) {
    if (items.isEmpty) return null;

    final normalized = query.toLowerCase().trim();
    double bestScore = 0.0;
    int bestIndex = -1;

    for (int i = 0; i < items.length; i++) {
      final searchText = getSearchText(items[i]).toLowerCase();
      final score = similarity(normalized, searchText);

      logger.debug('Matching "$normalized" with "$searchText": score = $score');

      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }

    // Return null if score is too low (less than 30% match)
    if (bestScore < 0.3 || bestIndex == -1) {
      logger.warning('No good match found for "$query" (best score: $bestScore)');
      return null;
    }

    logger.info('Best match for "$query": index=$bestIndex, score=$bestScore');
    return (index: bestIndex, item: items[bestIndex], score: bestScore);
  }
}

/// Extension methods for int
extension IntExtensions on int {
  int coerceAtLeast(int min) => this < min ? min : this;
  int coerceAtMost(int max) => this > max ? max : this;
}
