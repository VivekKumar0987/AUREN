import 'package:auren/src/catalog/experience.dart';
import 'package:auren/src/engine/selection_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selection skips already revealed experiences', () {
    final catalog = ExperienceCatalog(
      app: 'AUREN',
      declaredCount: 160,
      note: '',
      experiences: [
        _experience('AUREN-0001', 'First field note'),
        _experience('AUREN-0002', 'Second field note'),
      ],
    );

    final selected = const SelectionEngine().choose(
      catalog: catalog,
      revealedExperienceIds: {'AUREN-0001'},
      recentExperiences: const [],
      localDate: DateTime(2026, 8, 15),
    );

    expect(selected?.id, 'AUREN-0002');
  });

  test('selection returns null when every experience is revealed', () {
    final catalog = ExperienceCatalog(
      app: 'AUREN',
      declaredCount: 160,
      note: '',
      experiences: [_experience('AUREN-0001', 'Only field note')],
    );

    final selected = const SelectionEngine().choose(
      catalog: catalog,
      revealedExperienceIds: {'AUREN-0001'},
      recentExperiences: const [],
      localDate: DateTime(2026, 8, 15),
    );

    expect(selected, isNull);
  });
}

Experience _experience(String id, String title) {
  return Experience(
    id: id,
    title: title,
    instruction: 'Go outside and observe one real thing carefully.',
    status: 'strong_editorial_candidate_pending_field_test',
    repeatPolicy: ExperienceCatalog.expectedRepeatPolicy,
    consumerBrowsable: false,
    requiresSuccess: false,
    postExperienceQuestions: const [
      'Would you have done this without AUREN?',
      'Was it worth your time?',
    ],
    sharePrompt: 'Would you like to share the experience with someone?',
  );
}
