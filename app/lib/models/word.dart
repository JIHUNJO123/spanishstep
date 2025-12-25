class Word {
  final int id;
  final String word;
  final String partOfSpeech;
  final String definition;
  final String example;
  final String level;
  final Map<String, Translation> translations;

  Word({
    required this.id,
    required this.word,
    required this.partOfSpeech,
    required this.definition,
    required this.example,
    required this.level,
    required this.translations,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    final translationsMap = <String, Translation>{};
    final trans = json['translations'] as Map<String, dynamic>;
    
    trans.forEach((key, value) {
      translationsMap[key] = Translation.fromJson(value);
    });

    return Word(
      id: json['id'],
      word: json['word'],
      partOfSpeech: json['partOfSpeech'],
      definition: json['definition'],
      example: json['example'],
      level: json['level'],
      translations: translationsMap,
    );
  }
}

class Translation {
  final String definition;
  final String example;

  Translation({
    required this.definition,
    required this.example,
  });

  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
      definition: json['definition'],
      example: json['example'],
    );
  }
}
