enum GoalType { loseWeight, gainMass, maintenance }

extension GoalTypeExtension on GoalType {
  String get label {
    switch (this) {
      case GoalType.loseWeight: return 'Perder peso';
      case GoalType.gainMass: return 'Ganhar massa';
      case GoalType.maintenance: return 'Manutencao';
    }
  }
}

class Goal {
  final String id;
  String name;
  GoalType type;
  double? targetWeightKg;
  DateTime startDate;
  DateTime? targetDate;
  bool active;
  String? notes;
  DateTime createdAt, updatedAt;

  Goal({
    required this.id, required this.name, required this.type,
    this.targetWeightKg, required this.startDate, this.targetDate,
    this.active = true, this.notes, required this.createdAt, required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'type': type.name, 'targetWeightKg': targetWeightKg,
    'startDate': startDate.toIso8601String(), 'targetDate': targetDate?.toIso8601String(),
    'active': active, 'notes': notes,
    'createdAt': createdAt.toIso8601String(), 'updatedAt': updatedAt.toIso8601String(),
  };

  factory Goal.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return Goal(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Meta',
      type: GoalType.values.firstWhere((e) => e.name == json['type']?.toString(), orElse: () => GoalType.loseWeight),
      targetWeightKg: double.tryParse(json['targetWeightKg']?.toString() ?? ''),
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? now,
      targetDate: DateTime.tryParse(json['targetDate']?.toString() ?? ''),
      active: json['active'] == true || json['active']?.toString() == 'true',
      notes: json['notes']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? now,
    );
  }
}