import 'package:auren/src/catalog/experience.dart';
import 'package:auren/src/share/share_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'share template is premium plain text without private reflection data',
    () {
      final template = AurenShareTemplate.forExperience(
        experience: const Experience(
          id: 'AUREN-0011',
          title: 'The Last Stop',
          instruction: 'Take a familiar public-transport route past your usual stop and get off somewhere you do not know. For the first twenty minutes, do not use digital navigation.',
          status: 'strong_editorial_candidate_pending_field_test',
          repeatPolicy: ExperienceCatalog.expectedRepeatPolicy,
          consumerBrowsable: false,
          requiresSuccess: false,
          postExperienceQuestions: [
            'Would you have done this without AUREN?',
            'Was it worth your time?',
          ],
          sharePrompt: 'Would you like to share the experience with someone?',
        ),
        date: DateTime(2026, 8, 15),
      );

      expect(template.subject, 'AUREN: I experienced The Last Stop');
      expect(template.text, contains('AUREN'));
      expect(template.text, contains('FIELD EXPERIENCE 0011'));
      expect(template.text, contains('EXPERIENCED / 15 AUGUST 2026'));
      expect(template.text, contains('TITLE'));
      expect(template.text, contains('THE LAST STOP'));
      expect(template.text, contains('TASK'));
      expect(
        template.text,
        contains('Take a familiar public-transport route past your usual stop'),
      );
      expect(template.text, contains('------------------------------'));
      expect(template.text, contains('I experienced this through AUREN.'));
      expect(template.text, contains('You do not have to succeed.'));
      expect(template.text, contains('Failure counts. You were there.'));
      expect(template.text, contains('No feeds. No streaks.'));
      expect(template.text, isNot(contains('Would you have done this')));
      expect(template.text, isNot(contains('Was it worth your time')));
    },
  );
}
