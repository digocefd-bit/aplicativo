import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/models/models.dart';
import '../core/models/goal.dart';
import '../core/models/profile.dart';
import '../core/services/storage_service.dart';
import '../core/services/goal_service.dart';
import 'settings_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => ResultsScreenState();
}

class ResultsScreenState extends State<ResultsScreen> {
  UserProfile? _profile;
  List<BodyMeasurement> _measurements = [];
  List<Goal> _goals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final profile = await StorageService.loadProfile();
      final measurements = await StorageService.loadBodyMeasurements();
      final goals = await StorageService.loadGoals();

      measurements.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

      if (mounted) {
        setState(() {
          _profile = profile;
          _measurements = measurements;
          _goals = goals;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuracoes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProfileCard(theme),
                  const SizedBox(height: 16),
                  _buildWeightChart(theme),
                  const SizedBox(height: 16),
                  _buildGoalsSection(theme),
                  const SizedBox(height: 16),
                  _buildDisclaimerCard(theme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard(ThemeData theme) {
    if (_profile == null) {
      return const SizedBox.shrink();
    }

    final latestMeasurement = _measurements.isNotEmpty
        ? _measurements.where((m) => m.weightKg != null).toList().isNotEmpty
            ? _measurements.where((m) => m.weightKg != null).toList().last
            : null
        : null;

    final imc = latestMeasurement?.imc;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Meus dados', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildInfoRow(theme, 'Nome', _profile!.name),
            if (_profile!.age != null) _buildInfoRow(theme, 'Idade', '${_profile!.age} anos'),
            _buildInfoRow(theme, 'Genero', _profile!.genderLabel),
            if (_profile!.heightCm != null) _buildInfoRow(theme, 'Altura', '${_profile!.heightCm!.toStringAsFixed(0)} cm'),
            if (latestMeasurement?.weightKg != null)
              _buildInfoRow(theme, 'Peso atual', '${latestMeasurement!.weightKg!.toStringAsFixed(1)} kg'),
            if (imc != null) _buildInfoRow(theme, 'IMC', '${imc.toStringAsFixed(1)} ${_getImcLabel(imc)}'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _showAddMeasurementDialog,
              icon: const Icon(Icons.add),
              label: const Text('Registrar nova medicao'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getImcLabel(double imc) {
    if (imc < 18.5) return '(Abaixo do peso)';
    if (imc < 25) return '(Normal)';
    if (imc < 30) return '(Sobrepeso)';
    return '(Obesidade)';
  }

  Widget _buildWeightChart(ThemeData theme) {
    final withWeight = _measurements.where((m) => m.weightKg != null).toList();

    if (withWeight.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Evolucao de peso', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Nenhuma medicao registrada ainda.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final spots = withWeight.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weightKg!);
    }).toList();

    final minY = withWeight.map((m) => m.weightKg!).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = withWeight.map((m) => m.weightKg!).reduce((a, b) => a > b ? a : b) + 2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Evolucao de peso', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < withWeight.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('dd/MM').format(withWeight[index].measuredAt),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Metas', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: _showAddGoalDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nova meta'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_goals.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Nenhuma meta criada ainda. Crie uma meta para acompanhar seu progresso.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          ..._goals.map((goal) => _buildGoalCard(theme, goal)),
      ],
    );
  }

  Widget _buildGoalCard(ThemeData theme, Goal goal) {
    return FutureBuilder<double?>(
      future: GoalService.calculateProgress(goal),
      builder: (context, snapshot) {
        final progress = snapshot.data ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
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
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (!goal.active)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Inativa', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  goal.type.label,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                if (goal.targetWeightKg != null) ...[
                  const SizedBox(height: 8),
                  Text('Meta: ${goal.targetWeightKg!.toStringAsFixed(1)} kg'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Progresso: ${progress.toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDisclaimerCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Aviso importante', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Este aplicativo serve apenas para controle pessoal e lembretes. '
              'Ele NAO fornece prescricao, indicacao ou recomendacao de medicamentos, doses ou tratamentos. '
              'O uso de qualquer substancia e de responsabilidade exclusiva do usuario. '
              'Consulte sempre um profissional de saude qualificado.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddMeasurementDialog() async {
    final weightCtrl = TextEditingController();
    final waistCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova medicao'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Peso (kg)',
                hintText: 'Ex: 75.5',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: waistCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cintura (cm) - opcional',
                hintText: 'Ex: 85',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final weight = double.tryParse(weightCtrl.text.replaceAll(',', '.'));
              final waist = double.tryParse(waistCtrl.text.replaceAll(',', '.'));

              if (weight == null || weight <= 0) return;

              final now = DateTime.now();
              final day = DateTime(now.year, now.month, now.day);
              final measurement = BodyMeasurement(
                id: 'body_${now.millisecondsSinceEpoch}',
                measuredAt: day,
                weightKg: weight,
                waistCm: waist,
                heightCm: _profile?.heightCm,
              );

              final list = await StorageService.loadBodyMeasurements();
              list.add(measurement);
              await StorageService.saveBodyMeasurements(list);

              if (ctx.mounted) Navigator.pop(ctx);
              reload();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddGoalDialog() async {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    GoalType selectedType = GoalType.loseWeight;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nova meta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome da meta',
                  hintText: 'Ex: Emagrecer 10kg',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GoalType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: GoalType.values.map((t) {
                  return DropdownMenuItem(value: t, child: Text(t.label));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedType = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Peso alvo (kg)',
                  hintText: 'Ex: 70',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;

                final target = double.tryParse(targetCtrl.text.replaceAll(',', '.'));
                final now = DateTime.now();
                final goal = Goal(
                  id: 'goal_${now.millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  type: selectedType,
                  targetWeightKg: target,
                  startDate: now,
                  createdAt: now,
                  updatedAt: now,
                );

                await GoalService.addGoal(goal);

                if (ctx.mounted) Navigator.pop(ctx);
                reload();
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }
}