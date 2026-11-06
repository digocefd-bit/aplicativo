import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../core/services/storage_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _export(BuildContext context) async {
    try {
      final backup = await StorageService.exportBackup();
      final json = const JsonEncoder.withIndent('  ').convert(backup);

      final dir = await Directory.systemTemp.createTemp('backup');
      final file = File('${dir.path}/meu_protocolo_backup.json');
      await file.writeAsString(json);

      await Share.shareXFiles([XFile(file.path)], subject: 'Backup Meu Protocolo');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup gerado! Escolha onde salvar (Drive, email, etc).')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao exportar: $e')));
      }
    }
  }

  Future<void> _import(BuildContext context) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar backup'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Cole o conteudo do backup abaixo:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '{"version":2,"exportedAt":...}',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Importar')),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(result);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Backup invalido');
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restaurar backup?'),
          content: const Text('Isso vai SUBSTITUIR todos os dados atuais do app pelos dados do backup.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurar')),
          ],
        ),
      );

      if (confirm != true) return;

      await StorageService.importBackup(decoded);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restaurado com sucesso! Reinicie o app.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao importar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Configuracoes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Backup e Restauracao', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Exportar backup'),
              subtitle: const Text('Gera um arquivo .json para salvar no Drive, email, etc.'),
              onTap: () => _export(context),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Importar backup'),
              subtitle: const Text('Cole o JSON do backup para restaurar os dados'),
              onTap: () => _import(context),
            ),
          ),
          const SizedBox(height: 24),
          Text('Sobre', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Meu Protocolo v1.0.0\n\nEste aplicativo serve apenas para controle pessoal e lembretes. '
                'Ele NAO fornece prescricao, indicacao ou recomendacao de medicamentos, doses ou tratamentos. '
                'O uso de qualquer substancia e de responsabilidade exclusiva do usuario. '
                'Consulte sempre um profissional de saude qualificado.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}