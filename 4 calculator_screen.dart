import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _doseCtrl = TextEditingController();
  final _concentrationCtrl = TextEditingController();
  final _uiPerMlCtrl = TextEditingController();
  final _volumeCtrl = TextEditingController();

  String _unit = 'mg';
  String _result = '';

  @override
  void dispose() {
    _doseCtrl.dispose();
    _concentrationCtrl.dispose();
    _uiPerMlCtrl.dispose();
    _volumeCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final dose = double.tryParse(_doseCtrl.text.replaceAll(',', '.'));
    final concentration = double.tryParse(_concentrationCtrl.text.replaceAll(',', '.'));
    final uiPerMl = double.tryParse(_uiPerMlCtrl.text.replaceAll(',', '.'));

    if (dose == null || dose <= 0) {
      setState(() => _result = 'Informe uma dose valida.');
      return;
    }

    if (concentration == null || concentration <= 0) {
      setState(() => _result = 'Informe uma concentracao valida.');
      return;
    }

    // Cálculo: volume = dose / concentração
    final volume = dose / concentration;

    String resultText = 'Volume a aplicar: ${volume.toStringAsFixed(2)} mL';

    // Se UI/mL informado, calcular também em UI
    if (uiPerMl != null && uiPerMl > 0) {
      final ui = volume * uiPerMl;
      resultText += '\nEquivale a: ${ui.toStringAsFixed(1)} UI';
    }

    setState(() => _result = resultText);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calculadora de Dosagem',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calcule o volume em mL baseado na dose e concentracao.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _doseCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Dose desejada',
                        hintText: 'Ex: 5',
                        suffixText: _unit,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.medication),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _concentrationCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Concentracao (mg/mL)',
                        hintText: 'Ex: 20',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.science),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _uiPerMlCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'UI/mL (opcional)',
                        hintText: 'Ex: 100',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.speed),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _calculate,
                      icon: const Icon(Icons.calculate),
                      label: const Text('Calcular'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_result.isNotEmpty)
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resultado',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _result,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tabela de Conversao Rapida',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildConversionRow(theme, '1 mg = 1000 mcg'),
                    _buildConversionRow(theme, '1 mL = 100 UI (insulina padrao)'),
                    _buildConversionRow(theme, 'Seringa 1 mL = 100 UI'),
                    _buildConversionRow(theme, 'Seringa 0.5 mL = 50 UI'),
                    _buildConversionRow(theme, 'Seringa 0.3 mL = 30 UI'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionRow(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.arrow_right, size: 16),
          const SizedBox(width: 4),
          Text(text, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}