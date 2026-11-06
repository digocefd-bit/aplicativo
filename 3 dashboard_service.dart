import '../models/models.dart';
import '../models/goal.dart';
import 'storage_service.dart';

class DashboardStats {
  final List<ApplicationRecord> upcomingApplications;
  final int appliedToday;
  final int skippedToday;
  final int scheduledToday;
  final double? currentWeight;
  final double? targetWeight;
  final Goal? activeGoal;
  final List<Protocol> activeProtocols;

  DashboardStats({
    required this.upcomingApplications,
    required this.appliedToday,
    required this.skippedToday,
    required this.scheduledToday,
    required this.currentWeight,
    required this.targetWeight,
    required this.activeGoal,
    required this.activeProtocols,
  });
}

class DashboardService {
  static Future<DashboardStats> getStats() async {
    final protocols = await StorageService.loadProtocols();
    final applications = await StorageService.loadApplications();
    final goals = await StorageService.loadGoals();
    final body = await StorageService.loadBodyMeasurements();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final activeProtocols = protocols.where((p) => p.active).toList();

    // Aplicações de hoje
    final todayApps = applications.where((a) {
      final appDay = DateTime(a.scheduledAt.year, a.scheduledAt.month, a.scheduledAt.day);
      return appDay == today;
    }).toList();

    final appliedToday = todayApps.where((a) => a.status == ApplicationStatus.applied).length;
    final skippedToday = todayApps.where((a) => a.status == ApplicationStatus.skipped).length;
    final scheduledToday = todayApps.where((a) => a.status == ApplicationStatus.scheduled).length;

    // Próximas 5 aplicações futuras
    final upcoming = applications
        .where((a) =>
            a.status == ApplicationStatus.scheduled &&
            a.scheduledAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final upcomingApplications = upcoming.take(5).toList();

    // Peso atual (última medição com peso)
    double? currentWeight;
    if (body.isNotEmpty) {
      final withWeight = body.where((m) => m.weightKg != null).toList()
        ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
      if (withWeight.isNotEmpty) {
        currentWeight = withWeight.first.weightKg;
      }
    }

    // Meta ativa (primeira meta ativa)
    Goal? activeGoal;
    double? targetWeight;
    final activeGoals = goals.where((g) => g.active).toList();
    if (activeGoals.isNotEmpty) {
      activeGoal = activeGoals.first;
      targetWeight = activeGoal.targetWeightKg;
    }

    return DashboardStats(
      upcomingApplications: upcomingApplications,
      appliedToday: appliedToday,
      skippedToday: skippedToday,
      scheduledToday: scheduledToday,
      currentWeight: currentWeight,
      targetWeight: targetWeight,
      activeGoal: activeGoal,
      activeProtocols: activeProtocols,
    );
  }

  static Future<List<ApplicationRecord>> getUpcomingApplications({int limit = 5}) async {
    final applications = await StorageService.loadApplications();
    final now = DateTime.now();

    final upcoming = applications
        .where((a) =>
            a.status == ApplicationStatus.scheduled &&
            a.scheduledAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return upcoming.take(limit).toList();
  }

  static Future<Map<String, int>> getWeekSummary() async {
    final applications = await StorageService.loadApplications();
    final now = DateTime.now();

    // Segunda-feira desta semana
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = weekStart.add(const Duration(days: 7));

    final weekApps = applications.where((a) =>
        a.scheduledAt.isAfter(weekStart.subtract(const Duration(days: 1))) &&
        a.scheduledAt.isBefore(weekEnd)).toList();

    return {
      'applied': weekApps.where((a) => a.status == ApplicationStatus.applied).length,
      'skipped': weekApps.where((a) => a.status == ApplicationStatus.skipped).length,
      'scheduled': weekApps.where((a) => a.status == ApplicationStatus.scheduled).length,
      'total': weekApps.length,
    };
  }
}