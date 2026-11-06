class UserProfile {
  String name;
  DateTime? birthDate;
  double? heightCm;
  String? gender;

  UserProfile({this.name = '', this.birthDate, this.heightCm, this.gender});

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int a = now.year - birthDate!.year;
    if (now.month < birthDate!.month || (now.month == birthDate!.month && now.day < birthDate!.day)) {
      a--;
    }
    return a;
  }

  String get genderLabel {
    switch (gender) {
      case 'M': return 'Masculino';
      case 'F': return 'Feminino';
      case 'O': return 'Outro';
      default: return 'Nao informado';
    }
  }

  Map<String, dynamic> toJson() => {
    'name': name, 'birthDate': birthDate?.toIso8601String(), 'heightCm': heightCm, 'gender': gender,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name']?.toString() ?? '',
    birthDate: DateTime.tryParse(json['birthDate']?.toString() ?? ''),
    heightCm: double.tryParse(json['heightCm']?.toString() ?? ''),
    gender: json['gender']?.toString(),
  );
}