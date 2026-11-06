import 'package:flutter/material.dart';

enum RouteType { sc, im }
enum ScheduleFrequency { daily, weekly, intervalDays }
enum ApplicationStatus { scheduled, applied, skipped }
enum ProtocolCategory { testosterone, tirzepatide, klow, tesamorelin, ghFrag, glow, peptide, custom }

extension RouteTypeExtension on RouteType {
  String get label => this == RouteType.sc ? 'Subcutanea (SC)' : 'Intramuscular (IM)';
  String get shortLabel => this == RouteType.sc ? 'SC' : 'IM';
}

extension ScheduleFrequencyExtension on ScheduleFrequency {
  String get label {
    switch (this) {
      case ScheduleFrequency.daily: return 'Diario';
      case ScheduleFrequency.weekly: return 'Semanal';
      case ScheduleFrequency.intervalDays: return 'A cada X dias';
    }
  }
}

extension ApplicationStatusExtension on ApplicationStatus {
  String get label {
    switch (this) {
      case ApplicationStatus.scheduled: return 'Agendada';
      case ApplicationStatus.applied: return 'Aplicada';
      case ApplicationStatus.skipped: return 'Pulada';
    }
  }
}

extension ProtocolCategoryExtension on ProtocolCategory {
  String get label {
    switch (this) {
      case ProtocolCategory.testosterone: return 'Testosterona';
      case ProtocolCategory.tirzepatide: return 'Tirzepatida';
      case ProtocolCategory.klow: return 'Klow';
      case ProtocolCategory.tesamorelin: return 'Tesamorelin';
      case ProtocolCategory.ghFrag: return 'GH Frag';
      case ProtocolCategory.glow: return 'Glow';
      case ProtocolCategory.peptide: return 'Peptideo';
      case ProtocolCategory.custom: return 'Personalizado';
    }
  }
}

class ProtocolTime {
  final int hour, minute;
  final int? reminderOffsetMinutes;
  const ProtocolTime({required this.hour, required this.minute, this.reminderOffsetMinutes});
  String get formatted => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  Map<String, dynamic> toJson() => {'hour': hour, 'minute': minute, 'reminderOffsetMinutes': reminderOffsetMinutes};
  factory ProtocolTime.fromJson(Map<String, dynamic> json) => ProtocolTime(
    hour: int.tryParse(json['hour']?.toString() ?? '9') ?? 9,
    minute: int.tryParse(json['minute']?.toString() ?? '0') ?? 0,
    reminderOffsetMinutes: int.tryParse(json['reminderOffsetMinutes']?.toString() ?? ''),
  );
}

class Protocol {
  final String id;
  String name, abbreviation, colorHex, doseUnit;
  ProtocolCategory category;
  RouteType route;
  double defaultDose;
  double? concentrationMgPerMl, uiPerMg, uiPerMl;
  ScheduleFrequency frequency;
  int intervalDays, cooldownDays, defaultReminderOffsetMinutes;
  List<int> weekDays;
  List<ProtocolTime> times;
  DateTime startDate, createdAt, updatedAt;
  DateTime? endDate;
  bool active;
  String? notes, goalId;

  Protocol({
    required this.id, required this.name, required this.abbreviation,
    this.category = ProtocolCategory.custom, this.colorHex = '#00ACC1',
    required this.route, required this.defaultDose, required this.doseUnit,
    this.concentrationMgPerMl, this.uiPerMg, this.uiPerMl,
    required this.frequency, this.intervalDays = 1, List<int>? weekDays,
    List<ProtocolTime>? times, required this.startDate, this.endDate,
    this.active = true, this.cooldownDays = 7, this.defaultReminderOffsetMinutes = 15,
    this.notes, this.goalId, required this.createdAt, required this.updatedAt,
  }) : weekDays = weekDays ?? [], times = times ?? [];

  String get displayName => abbreviation.trim().isNotEmpty ? abbreviation : name;

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'abbreviation': abbreviation, 'category': category.name,
    'colorHex': colorHex, 'route': route.name, 'defaultDose': defaultDose, 'doseUnit': doseUnit,
    'concentrationMgPerMl': concentrationMgPerMl, 'uiPerMg': uiPerMg, 'uiPerMl': uiPerMl,
    'frequency': frequency.name, 'intervalDays': intervalDays, 'weekDays': weekDays,
    'times': times.map((t) => t.toJson()).toList(), 'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(), 'active': active, 'cooldownDays': cooldownDays,
    'defaultReminderOffsetMinutes': defaultReminderOffsetMinutes, 'notes': notes, 'goalId': goalId,
    'createdAt': createdAt.toIso8601String(), 'updatedAt': updatedAt.toIso8601String(),
  };

  factory Protocol.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return Protocol(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Protocolo',
      abbreviation: json['abbreviation']?.toString() ?? 'MED',
      category: ProtocolCategory.values.firstWhere((e) => e.name == json['category']?.toString(), orElse: () => ProtocolCategory.custom),
      colorHex: json['colorHex']?.toString() ?? '#00ACC1',
      route: RouteType.values.firstWhere((e) => e.name == json['route']?.toString(), orElse: () => RouteType.sc),
      defaultDose: double.tryParse(json['defaultDose']?.toString() ?? '0') ?? 0,
      doseUnit: json['doseUnit']?.toString() ?? 'mg',
      concentrationMgPerMl: double.tryParse(json['concentrationMgPerMl']?.toString() ?? ''),
      uiPerMg: double.tryParse(json['uiPerMg']?.toString() ?? ''),
      uiPerMl: double.tryParse(json['uiPerMl']?.toString() ?? ''),
      frequency: ScheduleFrequency.values.firstWhere((e) => e.name == json['frequency']?.toString(), orElse: () => ScheduleFrequency.daily),
      intervalDays: int.tryParse(json['intervalDays']?.toString() ?? '1') ?? 1,
      weekDays: (json['weekDays'] as List?)?.map((e) => int.tryParse(e.toString()) ?? 0).whereType<int>().toList() ?? [],
      times: (json['times'] as List?)?.map((e) => ProtocolTime.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map))).toList() ?? [],
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? now,
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? ''),
      active: json['active'] == true || json['active']?.toString() == 'true',
      cooldownDays: int.tryParse(json['cooldownDays']?.toString() ?? '7') ?? 7,
      defaultReminderOffsetMinutes: int.tryParse(json['defaultReminderOffsetMinutes']?.toString() ?? '15') ?? 15,
      notes: json['notes']?.toString(),
      goalId: json['goalId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? now,
    );
  }
}

class ApplicationRecord {
  final String id, protocolId;
  String occurrenceKey;
  DateTime scheduledAt, createdAt, updatedAt;
  DateTime? appliedAt;
  ApplicationStatus status;
  double doseValue;
  String doseUnit;
  RouteType route;
  String? siteId, notes, photoPath;
  double? weightKg;
  int? notificationId;
  bool manuallyCreated;

  ApplicationRecord({
    required this.id, required this.protocolId, required this.occurrenceKey,
    required this.scheduledAt, this.appliedAt, this.status = ApplicationStatus.scheduled,
    required this.doseValue, required this.doseUnit, required this.route,
    this.siteId, this.weightKg, this.notes, this.photoPath, this.notificationId,
    this.manuallyCreated = false, required this.createdAt, required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'protocolId': protocolId, 'occurrenceKey': occurrenceKey,
    'scheduledAt': scheduledAt.toIso8601String(), 'appliedAt': appliedAt?.toIso8601String(),
    'status': status.name, 'doseValue': doseValue, 'doseUnit': doseUnit, 'route': route.name,
    'siteId': siteId, 'weightKg': weightKg, 'notes': notes, 'photoPath': photoPath,
    'notificationId': notificationId, 'manuallyCreated': manuallyCreated,
    'createdAt': createdAt.toIso8601String(), 'updatedAt': updatedAt.toIso8601String(),
  };

  factory ApplicationRecord.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return ApplicationRecord(
      id: json['id']?.toString() ?? '',
      protocolId: json['protocolId']?.toString() ?? '',
      occurrenceKey: json['occurrenceKey']?.toString() ?? '',
      scheduledAt: DateTime.tryParse(json['scheduledAt']?.toString() ?? '') ?? now,
      appliedAt: DateTime.tryParse(json['appliedAt']?.toString() ?? ''),
      status: ApplicationStatus.values.firstWhere((e) => e.name == json['status']?.toString(), orElse: () => ApplicationStatus.scheduled),
      doseValue: double.tryParse(json['doseValue']?.toString() ?? '0') ?? 0,
      doseUnit: json['doseUnit']?.toString() ?? 'mg',
      route: RouteType.values.firstWhere((e) => e.name == json['route']?.toString(), orElse: () => RouteType.sc),
      siteId: json['siteId']?.toString(),
      weightKg: double.tryParse(json['weightKg']?.toString() ?? ''),
      notes: json['notes']?.toString(),
      photoPath: json['photoPath']?.toString(),
      notificationId: int.tryParse(json['notificationId']?.toString() ?? ''),
      manuallyCreated: json['manuallyCreated'] == true || json['manuallyCreated']?.toString() == 'true',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? now,
    );
  }
}

class InjectionSite {
  final String id, name, shortName;
  final RouteType route;
  final int cooldownDays;
  final bool active;
  const InjectionSite({required this.id, required this.name, required this.shortName, required this.route, required this.cooldownDays, this.active = true});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'shortName': shortName, 'route': route.name, 'cooldownDays': cooldownDays, 'active': active};
  factory InjectionSite.fromJson(Map<String, dynamic> json) => InjectionSite(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Local',
    shortName: json['shortName']?.toString() ?? 'Local',
    route: RouteType.values.firstWhere((e) => e.name == json['route']?.toString(), orElse: () => RouteType.sc),
    cooldownDays: int.tryParse(json['cooldownDays']?.toString() ?? '7') ?? 7,
    active: json['active'] == true || json['active']?.toString() == 'true',
  );
}

class BodyMeasurement {
  final String id;
  DateTime measuredAt;
  double? weightKg, heightCm, waistCm, armCm, chestCm, hipCm;
  String? notes;
  BodyMeasurement({required this.id, required this.measuredAt, this.weightKg, this.heightCm, this.waistCm, this.armCm, this.chestCm, this.hipCm, this.notes});
  double? get imc {
    if (weightKg == null || heightCm == null || heightCm! <= 0) return null;
    final h = heightCm! / 100;
    return weightKg! / (h * h);
  }
  Map<String, dynamic> toJson() => {'id': id, 'measuredAt': measuredAt.toIso8601String(), 'weightKg': weightKg, 'heightCm': heightCm, 'waistCm': waistCm, 'armCm': armCm, 'chestCm': chestCm, 'hipCm': hipCm, 'notes': notes};
  factory BodyMeasurement.fromJson(Map<String, dynamic> json) => BodyMeasurement(
    id: json['id']?.toString() ?? '',
    measuredAt: DateTime.tryParse(json['measuredAt']?.toString() ?? '') ?? DateTime.now(),
    weightKg: double.tryParse(json['weightKg']?.toString() ?? ''),
    heightCm: double.tryParse(json['heightCm']?.toString() ?? ''),
    waistCm: double.tryParse(json['waistCm']?.toString() ?? ''),
    armCm: double.tryParse(json['armCm']?.toString() ?? ''),
    chestCm: double.tryParse(json['chestCm']?.toString() ?? ''),
    hipCm: double.tryParse(json['hipCm']?.toString() ?? ''),
    notes: json['notes']?.toString(),
  );
}