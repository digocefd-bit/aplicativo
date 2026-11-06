import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import '../models/goal.dart';
import '../models/profile.dart';

class StorageService {
  static const String _protocolsKey = 'medcontrol_v2_protocols';
  static const String _applicationsKey = 'medcontrol_v2_applications';
  static const String _bodyKey = 'medcontrol_v2_body';
  static const String _sitesKey = 'medcontrol_v2_sites';
  static const String _goalsKey = 'medcontrol_v2_goals';
  static const String _profileKey = 'medcontrol_v2_profile';

  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static Future<void> saveProtocols(List<Protocol> protocols) async {
    await _storage.write(key: _protocolsKey, value: jsonEncode(protocols.map((p) => p.toJson()).toList()));
  }

  static Future<List<Protocol>> loadProtocols() async {
    final list = await _readList(_protocolsKey);
    return list.map((e) => Protocol.fromJson(e)).toList();
  }

  static Future<void> saveApplications(List<ApplicationRecord> applications) async {
    await _storage.write(key: _applicationsKey, value: jsonEncode(applications.map((a) => a.toJson()).toList()));
  }

  static Future<List<ApplicationRecord>> loadApplications() async {
    final list = await _readList(_applicationsKey);
    return list.map((e) => ApplicationRecord.fromJson(e)).toList();
  }

  static Future<void> saveBodyMeasurements(List<BodyMeasurement> measurements) async {
    await _storage.write(key: _bodyKey, value: jsonEncode(measurements.map((m) => m.toJson()).toList()));
  }

  static Future<List<BodyMeasurement>> loadBodyMeasurements() async {
    final list = await _readList(_bodyKey);
    return list.map((e) => BodyMeasurement.fromJson(e)).toList();
  }

  static Future<void> saveInjectionSites(List<InjectionSite> sites) async {
    await _storage.write(key: _sitesKey, value: jsonEncode(sites.map((s) => s.toJson()).toList()));
  }

  static Future<List<InjectionSite>> loadInjectionSites() async {
    final list = await _readList(_sitesKey);
    return list.map((e) => InjectionSite.fromJson(e)).toList();
  }

  static Future<void> saveGoals(List<Goal> goals) async {
    await _storage.write(key: _goalsKey, value: jsonEncode(goals.map((g) => g.toJson()).toList()));
  }

  static Future<List<Goal>> loadGoals() async {
    final list = await _readList(_goalsKey);
    return list.map((e) => Goal.fromJson(e)).toList();
  }

  static Future<void> saveProfile(UserProfile profile) async {
    await _storage.write(key: _profileKey, value: jsonEncode(profile.toJson()));
  }

  static Future<UserProfile?> loadProfile() async {
    final s = await _storage.read(key: _profileKey);
    if (s == null || s == 'null') return null;
    try {
      return UserProfile.fromJson(jsonDecode(s));
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> exportBackup() async {
    final protocols = await loadProtocols();
    final applications = await loadApplications();
    final body = await loadBodyMeasurements();
    final sites = await loadInjectionSites();
    final goals = await loadGoals();
    final profile = await loadProfile();
    return {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'protocols': protocols.map((p) => p.toJson()).toList(),
      'applications': applications.map((a) => a.toJson()).toList(),
      'bodyMeasurements': body.map((m) => m.toJson()).toList(),
      'injectionSites': sites.map((s) => s.toJson()).toList(),
      'goals': goals.map((g) => g.toJson()).toList(),
      'profile': profile?.toJson(),
    };
  }

  static Future<void> importBackup(Map<String, dynamic> backup) async {
    final protocols = _mapList(backup['protocols']).map((e) => Protocol.fromJson(e)).toList();
    final applications = _mapList(backup['applications']).map((e) => ApplicationRecord.fromJson(e)).toList();
    final body = _mapList(backup['bodyMeasurements']).map((e) => BodyMeasurement.fromJson(e)).toList();
    final sites = _mapList(backup['injectionSites']).map((e) => InjectionSite.fromJson(e)).toList();
    final goals = _mapList(backup['goals']).map((e) => Goal.fromJson(e)).toList();
    await saveProtocols(protocols);
    await saveApplications(applications);
    await saveBodyMeasurements(body);
    await saveInjectionSites(sites);
    await saveGoals(goals);
    final profileData = backup['profile'];
    if (profileData is Map<String, dynamic>) {
      await saveProfile(UserProfile.fromJson(profileData));
    }
  }

  static Future<void> clearAllV2() async {
    await _storage.delete(key: _protocolsKey);
    await _storage.delete(key: _applicationsKey);
    await _storage.delete(key: _bodyKey);
    await _storage.delete(key: _sitesKey);
    await _storage.delete(key: _goalsKey);
    await _storage.delete(key: _profileKey);
  }

  static Future<List<Map<String, dynamic>>> _readList(String key) async {
    final s = await _storage.read(key: key);
    if (s == null || s.isEmpty) return [];
    try {
      final decoded = jsonDecode(s);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }
}