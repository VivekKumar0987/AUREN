import 'dart:math';

import '../catalog/experience.dart';

class SelectionEngine {
  const SelectionEngine();

  Experience? choose({
    required ExperienceCatalog catalog,
    required Set<String> revealedExperienceIds,
    required List<Experience> recentExperiences,
    required DateTime localDate,
    int salt = 0,
  }) {
    final available = catalog.experiences
        .where((experience) => !revealedExperienceIds.contains(experience.id))
        .toList(growable: false);

    if (available.isEmpty) {
      return null;
    }

    final shuffled = available.toList(
      growable: false,
    )..shuffle(Random(_seedFor(localDate, revealedExperienceIds.length, salt)));

    for (final candidate in shuffled) {
      if (!_isNearRepeat(candidate, recentExperiences)) {
        return candidate;
      }
    }

    return shuffled.first;
  }

  bool isNearRepeatForTest(Experience candidate, List<Experience> recent) {
    return _isNearRepeat(candidate, recent);
  }

  int _seedFor(DateTime date, int revealedCount, int salt) {
    return (date.year * 10000) +
        (date.month * 100) +
        date.day +
        (revealedCount * 31) +
        salt;
  }

  bool _isNearRepeat(Experience candidate, List<Experience> recent) {
    for (final previous in recent.take(8)) {
      final similarity = _jaccardSimilarity(
        _tokens('${candidate.title} ${candidate.instruction}'),
        _tokens('${previous.title} ${previous.instruction}'),
      );
      if (similarity >= 0.38) {
        return true;
      }
    }
    return false;
  }

  Set<String> _tokens(String input) {
    const stopWords = {
      'a',
      'an',
      'and',
      'are',
      'as',
      'at',
      'be',
      'by',
      'do',
      'for',
      'from',
      'in',
      'into',
      'it',
      'of',
      'on',
      'one',
      'or',
      'that',
      'the',
      'then',
      'this',
      'to',
      'with',
      'without',
      'you',
      'your',
    };

    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.length > 2 && !stopWords.contains(token))
        .toSet();
  }

  double _jaccardSimilarity(Set<String> left, Set<String> right) {
    if (left.isEmpty || right.isEmpty) {
      return 0;
    }
    final intersection = left.intersection(right).length;
    final union = left.union(right).length;
    return intersection / union;
  }
}
