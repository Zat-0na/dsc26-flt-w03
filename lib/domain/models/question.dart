/// One practice question chosen for a student by the Masaraat backend.
final class Question {
  const Question({
    required this.id,
    required this.skillId,
    required this.stem,
    required this.choices,
  });

  final String id;
  final String skillId;
  final String stem;
  final List<String> choices;

  factory Question.fromJson(Map<String, Object?> json) {
    String getRequiredString(String key) {
      final value = json[key];

      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Invalid or missing field: $key');
      }

      return value;
    }

    final id = getRequiredString('id');
    final skillId = getRequiredString('skillId');
    final stem = getRequiredString('stem');

    final rawChoices = json['choices'];

    if (rawChoices is! List || rawChoices.length < 2 || rawChoices.length > 6) {
      throw const FormatException(
        'Choices must be a list containing 2 to 6 items',
      );
    }

    final choices = <String>[];

    for (final choice in rawChoices) {
      if (choice is! String || choice.trim().isEmpty) {
        throw const FormatException('Each choice must be a non-empty string');
      }

      choices.add(choice);
    }

    return Question(id: id, skillId: skillId, stem: stem, choices: choices);
  }
}
