/// Simple, fast fuzzy matcher for short words or phrases.
/// Returns best match + confidence.
Map<String, dynamic> bestMatch(String input, List<String> options) {
  input = input.toLowerCase().trim();
  double bestScore = 0.0;
  String? bestItem;

  for (final opt in options) {
    final candidate = opt.toLowerCase().trim();
    final score = _combinedSimilarity(input, candidate);
    if (score > bestScore) {
      bestScore = score;
      bestItem = opt;
    }
  }

  return {
    'match': bestItem ?? '',
    'score': bestScore,
  };
}

/// Combines two methods: Dice + LCS ratio.
double _combinedSimilarity(String a, String b) {
  final dice = _diceCoefficient(a, b);
  final lcs = _lcsRatio(a, b);
  return (dice * 0.6) + (lcs * 0.4);
}

/// Dice coefficient (Jaccard-like)
double _diceCoefficient(String a, String b) {
  if (a.isEmpty || b.isEmpty) return 0.0;
  final aBigrams = _bigrams(a);
  final bBigrams = _bigrams(b);
  int intersect = aBigrams.where((x) => bBigrams.contains(x)).length;
  return (2 * intersect) / (aBigrams.length + bBigrams.length);
}

List<String> _bigrams(String s) {
  if (s.length < 2) return [s];
  return [for (int i = 0; i < s.length - 1; i++) s.substring(i, i + 2)];
}

/// LCS (Longest Common Subsequence) ratio
double _lcsRatio(String a, String b) {
  final lcs = _lcsLength(a, b);
  return lcs / ((a.length + b.length) / 2);
}

int _lcsLength(String a, String b) {
  final dp = List.generate(a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
  for (int i = 1; i <= a.length; i++) {
    for (int j = 1; j <= b.length; j++) {
      if (a[i - 1] == b[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1] + 1;
      } else {
        dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
      }
    }
  }
  return dp[a.length][b.length];
}
