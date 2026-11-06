import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models/models.dart';
import '../core/models/goal.dart';
import '../core/services/storage_service.dart';
import '../core/services/protocol_service.dart';
import '../core/services/goal_service.dart';

class ProtocolFormScreen extends StatefulWidget {
  final Protocol? protocol;
  const ProtocolFormScreen({super.key, this.protocol});

  @override
  State<ProtocolFormScreen> createState() => _ProtocolFormScreenState();
}

class _ProtocolFormScreenState extends State<ProtocolFormScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _abbrCtrl;
  late TextEditingController _doseCtrl;
  late TextEditingController _intervalCtrl;
  late TextEditingController _concentrationCtrl;
  late TextEditingController _uiPerMgCtrl;
  late TextEditingController _reminderCtrl;
  late TextEditingController _cooldownCtrl;

  ProtocolCategory _category = ProtocolCategory.custom;
  RouteType _route = RouteType.sc;
  String _unit = 'mg';
  String _color = '#00ACC1';
  ScheduleFrequency _freq = ScheduleFrequency.daily;
  List<int> _weekDays = [];
  List<ProtocolTime> _times = [];
  DateTime _startDate = DateTime.now();
  String? _goalId;
  List<Goal> _goals = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.protocol;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _abbrCtrl = TextEditingController(text: p?.abbreviation ?? '');
    _doseCtrl = TextEditingController(text: p != null ? p.defaultDose.toString().replaceAll('.', ',') : '');
    _intervalCtrl = TextEditingController(text: p?.intervalDays.toString() ?? '3');
    _concentrationCtrl = TextEditingController(text: p?.concentrationMgPerMl?.toString().replaceAll('.', ',') ?? '');
    _uiPerMgCtrl = TextEditingController(text: p?.uiPerMg?.toString().replaceAll('.', ',') ?? '');
    _reminderCtrl = TextEditingController(text: p?.defaultReminderOffsetMinutes.toString() ?? '15');
    _cooldownCtrl = TextEditingController(text: p?.cooldownDays.toString() ?? '7');

    if (p != null) {
      _category = p.category;
      _route = p.route;
      _unit = p.doseUnit;
      _color = p.colorHex;
      _freq = p.frequency;
      _weekDays = List.from(p.weekDays);
      _times = List.from(p.times);
      _startDate = p.startDate;
      _goalId = p.goalId;
    } else {
      _times.add(const ProtocolTime(hour: 9, minute: 0, reminderOffsetMinutes: 15));
    }

    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goals = await GoalService.loadGoals();
    if (mounted) setState(() => _goals = goals);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _abbrCtrl.dispose();
    _doseCtrl.dispose();
    _intervalCtrl.dispose();
    _concentrationCtrl.dispose();
    _uiPerMgCtrl.dispose();
    _reminderCtrl.dispose();
    _cooldownCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Informe o nome do protocolo.');
      return;
    }
    if (_times.isEmpty) {
      _snack('Adicione pelo menos um horario.');
      return;
    }

    final dose = double.tryParse(_doseCtrl.text.replaceAll(',', '.')) ?? 0;
    final now = DateTime.now();

    setState(() => _saving = true);

    try {
      final protocol = Protocol(
        id: widget.protocol?.id ?? 'protocol_${now.millisecondsSinceEpoch}',
        name: _nameCtrl.text.trim(),
        abbreviation: _abbrCtrl.text.trim(),
        category: _category,
        colorHex: _color,
        route: _route,
        defaultDose: dose,
        doseUnit: _unit,
        concentrationMgPerMl: double.tryParse(_concentrationCtrl.text.replaceAll(',', '.')),
        uiPerMg: double.tryParse(_uiPerMgCtrl.text.replaceAll(',', '.')),
        frequency: _freq,
        intervalDays: int.tryParse(_intervalCtrl.text) ?? 1,
        weekDays: _weekDays,
        times: _times,
        startDate: _startDate,
        cooldownDays: int.tryParse(_cooldownCtrl.text) ?? 7,
        defaultReminderOffsetMinutes: int.tryParse(_reminderCtrl.text) ?? 15,
        goalId: _goalId,
        createdAt: widget.protocol?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.protocol == null) {
        await ProtocolService.addProtocol(protocol);
      } else {
        await ProtocolService.updateProtocol(protocol);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _snack('Erro ao salvar: $e');
        setState(() => _saving = false);
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.protocol == null ? 'Novo Protocolo' : 'Editar Protocolo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(theme, 'Informacoes basicas', [
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome do protocolo',
                hintText: 'Ex: Testosterona Semanal',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _abbrCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Abreviacao',
                hintText: 'Ex: TESTO',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProtocolCategory>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder()),
              items: ProtocolCategory.values.map((c) {
                return DropdownMenuItem(value: c, child: Text(c.label));
              }).toList(),
              onChanged: (v) => setState(() => _category = v ?? ProtocolCategory.custom),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RouteType>(
              value: _route,
              decoration: const InputDecoration(labelText: 'Via de administracao', border: OutlineInputBorder()),
              items: RouteType.values.map((r) {
                return DropdownMenuItem(value: r, child: Text(r.label));
              }).toList(),
              onChanged: (v) => setState(() => _route = v ?? RouteType.sc),
            ),
          ]),
          const SizedBox(height: 16),

          _buildSection(theme, 'Dosagem', [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _doseCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Dose padrao',
                    suffixText: _unit,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _unit,
                items: const [
                  DropdownMenuItem(value: 'mg', child: Text('mg')),
                  DropdownMenuItem(value: 'mcg', child: Text('mcg')),
                  DropdownMenuItem(value: 'UI', child: Text('UI')),
                  DropdownMenuItem(value: 'mL', child: Text('mL')),
                ],
                onChanged: (v) => setState(() => _unit = v ?? 'mg'),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _concentrationCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Concentracao (mg/mL)',
                hintText: 'Ex: 200',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _uiPerMgCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'UI por mg (opcional)',
                hintText: 'Ex: 2.5',
                border: OutlineInputBorder(),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          _buildSection(theme, 'Frequencia', [
            DropdownButtonFormField<ScheduleFrequency>(
              value: _freq,
              decoration: const InputDecoration(labelText: 'Frequencia', border: OutlineInputBorder()),
              items: ScheduleFrequency.values.map((f) {
                return DropdownMenuItem(value: f, child: Text(f.label));
              }).toList(),
              onChanged: (v) => setState(() => _freq = v ?? ScheduleFrequency.daily),
            ),
            if (_freq == ScheduleFrequency.intervalDays) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _intervalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Intervalo (dias)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (_freq == ScheduleFrequency.weekly) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildWeekDayChip(theme, 1, 'Seg'),
                  _buildWeekDayChip(theme, 2, 'Ter'),
                  _buildWeekDayChip(theme, 3, 'Qua'),
                  _buildWeekDayChip(theme, 4, 'Qui'),
                  _buildWeekDayChip(theme, 5, 'Sex'),
                  _buildWeekDayChip(theme, 6, 'Sab'),
                  _buildWeekDayChip(theme, 7, 'Dom'),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text('Horarios de aplicacao:', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ..._times.map((t) => _buildTimeRow(theme, t)),
            TextButton.icon(
              onPressed: _addTime,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar horario'),
            ),
          ]),
          const SizedBox(height: 16),

          _buildSection(theme, 'Configuracoes', [
            TextField(
              controller: _reminderCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Lembrete (minutos antes)',
                hintText: 'Ex: 15',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cooldownCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cooldown entre locais (dias)',
                hintText: 'Ex: 7',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: theme.colorScheme.outline),
              ),
              leading: const Icon(Icons.calendar_today),
              title: const Text('Data de inicio'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (d != null) setState(() => _startDate = d);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _goalId,
              decoration: const InputDecoration(
                labelText: 'Meta vinculada (opcional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Nenhuma')),
                ..._goals.map((g) => DropdownMenuItem<String?>(value: g.id, child: Text(g.name))),
              ],
              onChanged: (v) => setState(() => _goalId = v),
            ),
          ]),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            label: Text(_saving ? 'Salvando...' : 'Salvar Protocolo'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildWeekDayChip(ThemeData theme, int day, String label) {
    final selected = _weekDays.contains(day);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _weekDays.add(day);
          } else {
            _weekDays.remove(day);
          }
        });
      },
    );
  }

  Widget _buildTimeRow(ThemeData theme, ProtocolTime time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              time.formatted,
              style: theme.textTheme.titleSmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _editTime(time),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            onPressed: () => setState(() => _times.remove(time)),
          ),
        ],
      ),
    );
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _times.add(ProtocolTime(hour: picked.hour, minute: picked.minute, reminderOffsetMinutes: 15));
      });
    }
  }

  Future<void> _editTime(ProtocolTime time) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: time.hour, minute: time.minute),
    );
    if (picked != null) {
      setState(() {
        final index = _times.indexOf(time);
        if (index != -1) {
          _times[index] = ProtocolTime(
            hour: picked.hour,
            minute: picked.minute,
            reminderOffsetMinutes: time.reminderOffsetMinutes,
          );
        }
      });
    }
  }
}