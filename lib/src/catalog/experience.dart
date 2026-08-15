class Experience {
  const Experience({
    required this.id,
    required this.title,
    required this.instruction,
    required this.status,
    required this.repeatPolicy,
    required this.consumerBrowsable,
    required this.requiresSuccess,
    required this.postExperienceQuestions,
    required this.sharePrompt,
  });

  final String id;
  final String title;
  final String instruction;
  final String status;
  final String repeatPolicy;
  final bool consumerBrowsable;
  final bool requiresSuccess;
  final List<String> postExperienceQuestions;
  final String sharePrompt;

  factory Experience.fromJson(Map<String, Object?> json) {
    final questions = json['post_experience_questions'];

    return Experience(
      id: _readString(json, 'experience_id'),
      title: _readString(json, 'title'),
      instruction: _readString(json, 'instruction'),
      status: _readString(json, 'status'),
      repeatPolicy: _readString(json, 'repeat_policy'),
      consumerBrowsable: json['consumer_browsable'] == true,
      requiresSuccess: json['requires_success'] == true,
      postExperienceQuestions: questions is List
          ? questions.map((value) => value.toString()).toList(growable: false)
          : const <String>[],
      sharePrompt: _readString(json, 'share_prompt'),
    );
  }

  static String _readString(Map<String, Object?> json, String key) {
    final value = json[key];
    return value is String ? value.trim() : '';
  }
}

class ExperienceCatalog {
  const ExperienceCatalog({
    required this.app,
    required this.declaredCount,
    required this.note,
    required this.experiences,
  });

  static const int requiredCount = 160;
  static const String expectedRepeatPolicy = 'never_show_again_once_revealed';

  final String app;
  final int declaredCount;
  final String note;
  final List<Experience> experiences;

  Map<String, Experience> get byId => {
    for (final experience in experiences) experience.id: experience,
  };

  List<String> validate() {
    final errors = <String>[];
    final ids = <String>{};
    final titles = <String>{};

    if (declaredCount != requiredCount) {
      errors.add('Catalog declared count must be $requiredCount.');
    }
    if (experiences.length != requiredCount) {
      errors.add('Catalog actual count must be $requiredCount.');
    }

    for (final experience in experiences) {
      if (experience.id.isEmpty) {
        errors.add('An experience is missing experience_id.');
      } else if (!ids.add(experience.id)) {
        errors.add('Duplicate experience_id: ${experience.id}.');
      }

      if (experience.title.isEmpty) {
        errors.add('${experience.id} is missing title.');
      } else if (!titles.add(experience.title.toLowerCase())) {
        errors.add('Duplicate title: ${experience.title}.');
      }

      if (experience.instruction.isEmpty) {
        errors.add('${experience.id} is missing instruction.');
      }
      if (experience.postExperienceQuestions.length < 2) {
        errors.add('${experience.id} must have both reflection questions.');
      }
      if (experience.consumerBrowsable) {
        errors.add('${experience.id} must not be consumer-browsable.');
      }
      if (experience.requiresSuccess) {
        errors.add('${experience.id} must not require success.');
      }
      if (experience.repeatPolicy != expectedRepeatPolicy) {
        errors.add('${experience.id} has unsupported repeat policy.');
      }
    }

    return errors;
  }
}
