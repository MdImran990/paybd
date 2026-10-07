class SavingsGoal {
  final String id;
  final String name;
  final int targetMinor; // paisa
  final int savedMinor; // paisa

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetMinor,
    required this.savedMinor,
  });

  double get progress {
    if (targetMinor <= 0) return 0;
    final p = savedMinor / targetMinor;
    return p > 1 ? 1.0 : p;
  }

  SavingsGoal copyWith({int? savedMinor}) => SavingsGoal(
        id: id,
        name: name,
        targetMinor: targetMinor,
        savedMinor: savedMinor ?? this.savedMinor,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetMinor': targetMinor,
        'savedMinor': savedMinor,
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> j) => SavingsGoal(
        id: j['id'] as String,
        name: j['name'] as String,
        targetMinor: j['targetMinor'] as int,
        savedMinor: j['savedMinor'] as int,
      );
}
