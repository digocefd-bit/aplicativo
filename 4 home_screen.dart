import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models/models.dart';
import '../core/models/goal.dart';
import '../core/services/dashboard_service.dart';
import '../core/services/application_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/rotation_service.dart';
import '../core/services/reminder_sync_service.dart';
import '../core/services/goal_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  DashboardStats? _stats;
  bool _loading = true;
  double? _goalProgress;
  double? _weightChange;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final stats = await DashboardService.getStats();

      double? progress;
      double? change;
      if (stats.activeGoal != null) {
        progress = await GoalService.calculateProgress(stats.activeGoal!);
        change = await GoalService.getWeightChange(stats.activeGoal!);
      }

      if (mounted) {
        setState(() {
          _stats = stats;
          _goalProgress = progress;
          _weightChange = change;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _syncReminders() async {
    try {
      await ReminderSyncService.syncAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lembretes sincronizados!')),
        );
      }
      reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao sincronizar lembretes.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Protocolo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar lembretes',
            onPressed: _syncReminders,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCards(theme),
                  const SizedBox(height: 16),
                  _buildGoalCard(theme),
                  const SizedBox(height: 16),
                  _buildUpcomingSection(theme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme) {
    if (_stats == null) return const SizedBox.shrink();

    return Row(
      children: [
        _buildStatCard(
          theme,
          icon: Icons.check_circle,
          color: Colors.green,
          label: 'Aplicadas hoje',
          value: '${_stats!.appliedToday}',
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          theme,
          icon: Icons.pending,
          color: Colors.orange,
          label: 'Pendentes hoje',
          value: '${_stats!.scheduledToday}',
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          theme,
          icon: Icons.medication,
          color: theme.colorScheme.primary,
          label: 'Protocolos ativos',
          value: '${_stats!.activeProtocols.length}',
        ),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(ThemeData theme) {
    if (_stats == null) return const SizedBox.shrink();

    final goal = _stats!.activeGoal;
    if (goal == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flag, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Meta', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Nenhuma meta ativa. Crie uma na aba Resultados.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    goal.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_stats!.currentWeight != null && _stats!.targetWeight != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Peso atual',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Meta',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_stats!.currentWeight!.toStringAsFixed(1)} kg',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_stats!.targetWeight!.toStringAsFixed(1)} kg',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (_goalProgress ?? 0) / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progresso: ${(_goalProgress ?? 0).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_weightChange != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _weightChange! < 0
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_weightChange! > 0 ? '+' : ''}${_weightChange!.toStringAsFixed(1)} kg',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _weightChange! < 0 ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ] else ...[
              Text(
                'Registre seu peso na aba Resultados para acompanhar o progresso.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSection(ThemeData theme) {
    if (_stats == null) return const SizedBox.shrink();

    final upcoming = _stats!.upcomingApplications;
    if (upcoming.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Proximas aplicacoes', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Nenhuma aplicacao agendada. Crie um protocolo para comecar.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Proximas aplicacoes', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...upcoming.map((app) => _buildUpcomingCard(theme, app)),
      ],
    );
  }

  Widget _buildUpcomingCard(ThemeData theme, ApplicationRecord app) {
    return FutureBuilder<List<Protocol>>(
      future: StorageService.loadProtocols(),
      builder: (context, snapshot) {
        final protocols = snapshot.data ?? [];
        final protocol = protocols.firstWhere(
          (p) => p.id == app.protocolId,
          orElse: () => Protocol(
            id: '',
            name: 'Protocolo',
            abbreviation: 'PRO',
            route: RouteType.sc,
            defaultDose: 0,
            doseUnit: 'mg',
            frequency: ScheduleFrequency.daily,
            startDate: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.medication,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(
              protocol.displayName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${DateFormat('dd/MM/yyyy HH:mm').format(app.scheduledAt)} - ${app.doseValue} ${app.doseUnit}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              tooltip: 'Marcar como aplicada',
              onPressed: () => _markApplied(app),
            ),
          ),
        );
      },
    );
  }

  Future<void> _markApplied(ApplicationRecord app) async {
    final protocols = await StorageService.loadProtocols();
    final protocol = protocols.firstWhere(
      (p) => p.id == app.protocolId,
      orElse: () => protocols.first,
    );

    final sites = await StorageService.loadInjectionSites();
    final availableSites = RotationService.getAvailableSites(
      route: protocol.route,
      sites: sites,
    );

    String? selectedSiteId = await ApplicationService.suggestNextSite(protocolId: app.protocolId);

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Confirmar aplicacao'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dose: ${app.doseValue} ${app.doseUnit}'),
              const SizedBox(height: 8),
              if (availableSites.isNotEmpty) ...[
                const Text('Local de aplicacao:'),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: selectedSiteId,
                  isExpanded: true,
                  items: availableSites.map((s) {
                    return DropdownMenuItem(value: s.id, child: Text(s.name));
                  }).toList(),
                  onChanged: (v) {
                    setDialogState(() {
                      selectedSiteId = v;
                    });
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    await ApplicationService.markAsApplied(
      applicationId: app.id,
      siteId: selectedSiteId,
    );

    reload();
  }
}