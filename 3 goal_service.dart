import '../models/models.dart';
import '../models/goal.dart';
import 'storage_service.dart';

class GoalService {
  static Future<List<Goal>> loadGoals() async {
    return await StorageService.loadGoals();
  }

  static Future<Goal> addGoal(Goal goal) async {
    final goals = await StorageService.loadGoals();
    goals.add(goal);
    await StorageService.saveGoals(goals);
    return goal;
  }

  static Future<void> updateGoal(Goal goal) async {
    final goals = await StorageService.loadGoals();
    final index = goals.indexWhere((g) => g.id == goal.id);
    if (index == -1) return;

    goal.updatedAt = DateTime.now();
    goals[index] = goal;
    await StorageService.saveGoals(goals);
  }

  static Future<void> deleteGoal(String goalId) async {
    final goals = await StorageService.loadGoals();
    goals.removeWhere((g) => g.id == goalId);
    await StorageService.saveGoals(goals);

    // Desvincular protocolos desta meta
    final protocols = await StorageService.loadProtocols();
    for (final p in protocols) {
      if (p.goalId == goalId) {
        p.goalId = null;
      }
    }
    await StorageService.saveProtocols(protocols);
  }

  static Future<void> toggleGoalActive(String goalId) async {
    final goals = await StorageService.loadGoals();
    final index = goals.indexWhere((g) => g.id == goalId);
    if (index == -1) return;

    final goal = goals[index];
    goal.active = !goal.active;
    goal.updatedAt = DateTime.now();

    goals[index] = goal;
    await StorageService.saveGoals(goals);
  }

  static Future<List<Protocol>> getProtocolsForGoal(String goalId) async {
    final protocols = await StorageService.loadProtocols();
    return protocols.where((p) => p.goalId == goalId).toList();
  }

  static Future<double?> calculateProgress(Goal goal) async {
    if (goal.targetWeightKg == null) return null;

    final body = await StorageService.loadBodyMeasurements();
    if (body.isEmpty) return null;

    // Ordenar por data
    body.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    // Encontrar peso inicial (primeira medição com peso após o início da meta)
    final afterStart = body.where((m) =>
        m.weightKg != null &&
        m.measuredAt.isAfter(goal.startDate.subtract(const Duration(days: 1)))).toList();

    if (afterStart.isEmpty) return null;

    final initialWeight = afterStart.first.weightKg;
    final currentWeight = afterStart.last.weightKg;
    final targetWeight = goal.targetWeightKg;

    if (initialWeight == null || currentWeight == null || targetWeight == null) return null;

    final totalDistance = (targetWeight - initialWeight).abs();
    if (totalDistance == 0) return 100.0;

    final currentDistance = (targetWeight - currentWeight).abs();
    final progress = ((totalDistance - currentDistance) / totalDistance) * 100;

    return progress.clamp(0, 100);
  }

  static Future<double?> getWeightChange(Goal goal) async {
    final body = await StorageService.loadBodyMeasurements();
    if (body.isEmpty) return null;

    body.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    final afterStart = body.where((m) =>
        m.weightKg != null &&
        m.measuredAt.isAfter(goal.startDate.subtract(const Duration(days: 1)))).toList();

    if (afterStart.isEmpty) return null;

    final initialWeight = afterStart.first.weightKg;
    final currentWeight = afterStart.last.weightKg;

    if (initialWeight == null || currentWeight == null) return null;

    return currentWeight - initialWeight;
  }
}