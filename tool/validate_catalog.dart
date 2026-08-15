import 'dart:convert';
import 'dart:io';

const requiredCount = 160;
const expectedRepeatPolicy = 'never_show_again_once_revealed';

void main() {
  final file = File('AUREN_Strong_160_Experiences.json');
  if (!file.existsSync()) {
    stderr.writeln('Missing AUREN_Strong_160_Experiences.json');
    exitCode = 1;
    return;
  }

  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    stderr.writeln('Catalog root must be an object.');
    exitCode = 1;
    return;
  }

  final experiences = decoded['experiences'];
  if (experiences is! List) {
    stderr.writeln('Catalog experiences must be a list.');
    exitCode = 1;
    return;
  }

  final errors = <String>[];
  final ids = <String>{};
  final titles = <String>{};

  if (decoded['count'] != requiredCount) {
    errors.add('Declared count must be $requiredCount.');
  }
  if (experiences.length != requiredCount) {
    errors.add('Actual count must be $requiredCount.');
  }

  for (final raw in experiences) {
    if (raw is! Map) {
      errors.add('Every experience must be an object.');
      continue;
    }
    final row = raw.cast<String, Object?>();
    final id = row['experience_id']?.toString().trim() ?? '';
    final title = row['title']?.toString().trim() ?? '';
    final instruction = row['instruction']?.toString().trim() ?? '';
    final questions = row['post_experience_questions'];

    if (id.isEmpty || !ids.add(id)) {
      errors.add('Missing or duplicate id: $id.');
    }
    if (title.isEmpty || !titles.add(title.toLowerCase())) {
      errors.add('Missing or duplicate title for $id.');
    }
    if (instruction.isEmpty) {
      errors.add('$id is missing instruction.');
    }
    if (questions is! List || questions.length < 2) {
      errors.add('$id is missing the two reflection questions.');
    }
    if (row['consumer_browsable'] == true) {
      errors.add('$id must not be consumer browsable.');
    }
    if (row['requires_success'] == true) {
      errors.add('$id must not require success.');
    }
    if (row['repeat_policy'] != expectedRepeatPolicy) {
      errors.add('$id has unsupported repeat policy.');
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln(errors.join('\n'));
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Catalog validation passed: $requiredCount strong experiences.',
  );
}
