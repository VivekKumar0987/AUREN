import '../app/auren_controller.dart';
import '../catalog/experience.dart';

class AurenShareTemplate {
  const AurenShareTemplate({required this.subject, required this.text});

  final String subject;
  final String text;

  static AurenShareTemplate forExperience({
    required Experience experience,
    required DateTime date,
  }) {
    final fieldNumber = experience.id.replaceAll('AUREN-', '');
    final title = experience.title.toUpperCase();
    final instruction = _wrap(experience.instruction);

    return AurenShareTemplate(
      subject: 'AUREN: I experienced ${experience.title}',
      text: [
        'AUREN',
        'FIELD EXPERIENCE $fieldNumber',
        'EXPERIENCED / ${AurenController.formatDate(date)}',
        '',
        '------------------------------',
        'TITLE',
        title,
        '------------------------------',
        '',
        'TASK',
        instruction,
        '',
        'I experienced this through AUREN.',
        'You do not have to succeed. You only have to experience it.',
        'Failure counts. You were there.',
        '',
        'One day. One Experience. No feeds. No streaks.',
      ].join('\n'),
    );
  }

  static String _wrap(String input, {int width = 68}) {
    final words = input.trim().split(RegExp(r'\s+'));
    final lines = <String>[];
    final current = StringBuffer();

    for (final word in words) {
      if (current.isEmpty) {
        current.write(word);
        continue;
      }
      if (current.length + word.length + 1 > width) {
        lines.add(current.toString());
        current
          ..clear()
          ..write(word);
      } else {
        current
          ..write(' ')
          ..write(word);
      }
    }

    if (current.isNotEmpty) {
      lines.add(current.toString());
    }
    return lines.join('\n');
  }
}
