import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models/profile.dart';
import '../core/models/models.dart';
import '../core/services/storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  const OnboardingScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  DateTime? _birthDate;
  String? _gender;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Por favor, informe seu nome.');
      return;
    }
    final height = double.tryParse(_heightCtrl.text.replaceAll(',', '.'));
    final weight = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    if (height == null || height <= 0) {
      _snack('Informe uma altura valida (em cm).');
      return;
    }
    if (weight == null || weight <= 0) {
      _snack('Informe um peso inicial valido (em kg).');
      return;
    }

    setState(() => _saving = true);

    try {
      final profile = UserProfile(
        name: _nameCtrl.text.trim(),
        birthDate: _birthDate,
        heightCm: height,
        gender: _gender,
      );
      await StorageService.saveProfile(profile);

      final today = DateTime.now();
      final day = DateTime(today.year, today.month, today.day);
      final measurement = BodyMeasurement(
        id: 'body_${day.year}_${day.month}_${day.day}_onboarding',
        measuredAt: day,
        weightKg: weight,
        heightCm: height,
      );
      final list = await StorageService.loadBodyMeasurements();
      list.add(measurement);
      await StorageService.saveBodyMeasurements(list);

      if (mounted) widget.onCompleted();
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Icon(Icons.favorite, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Bem-vindo ao Meu Protocolo',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vamos comecar com alguns dados basicos para personalizar sua experiencia.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),

                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Seu nome',
                      hintText: 'Ex: Joao Silva',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: theme.colorScheme.outline),
                    ),
                    leading: const Icon(Icons.cake_outlined),
                    title: const Text('Data de nascimento'),
                    subtitle: Text(_birthDate != null ? DateFormat('dd/MM/yyyy').format(_birthDate!) : 'Nao informada'),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _birthDate ?? DateTime(1990, 1, 1),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState(() => _birthDate = d);
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _heightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Altura (cm)',
                          hintText: 'Ex: 175',
                          prefixIcon: Icon(Icons.height),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Peso atual (kg)',
                          hintText: 'Ex: 80.5',
                          prefixIcon: Icon(Icons.monitor_weight_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Genero (opcional)',
                      prefixIcon: Icon(Icons.wc_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'M', child: Text('Masculino')),
                      DropdownMenuItem(value: 'F', child: Text('Feminino')),
                      DropdownMenuItem(value: 'O', child: Text('Outro')),
                      DropdownMenuItem(value: 'N', child: Text('Prefiro nao informar')),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 32),

                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.arrow_forward),
                    label: Text(_saving ? 'Salvando...' : 'Comecar'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Seus dados ficam armazenados apenas neste dispositivo. Voce podera exportar um backup a qualquer momento.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}