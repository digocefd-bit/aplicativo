import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models/models.dart';
import '../core/services/protocol_service.dart';
import 'protocol_form_screen.dart';

class ProtocolsScreen extends StatefulWidget {
  const ProtocolsScreen({super.key});

  @override
  State<ProtocolsScreen> createState() => ProtocolsScreenState();
}

class ProtocolsScreenState extends State<ProtocolsScreen> {
  List<Protocol> _protocols = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    _loadProtocols();
  }

  Future<void> _loadProtocols() async {
    setState(() => _loading = true);
    try {
      final protocols = await ProtocolService.loadProtocols();
      if (mounted) {
        setState(() {
          _protocols = protocols;
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
      appBar: AppBar(title: const Text('Protocolos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(null),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _protocols.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadProtocols,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _protocols.length,
                    itemBuilder: (context, index) {
                      return _buildProtocolCard(theme, _protocols[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum protocolo ainda',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no botao + para criar seu primeiro protocolo',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolCard(ThemeData theme, Protocol protocol) {
    final color = _parseColor(protocol.colorHex);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openForm(protocol),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          protocol.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          protocol.category.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!protocol.active)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Inativo',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(theme, Icons.route, protocol.route.shortLabel),
                  const SizedBox(width: 8),
                  _buildInfoChip(theme, Icons.schedule, protocol.frequency.label),
                  const SizedBox(width: 8),
                  _buildInfoChip(theme, Icons.medication, '${protocol.defaultDose} ${protocol.doseUnit}'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      protocol.active ? Icons.pause_circle : Icons.play_circle,
                      color: protocol.active ? Colors.orange : Colors.green,
                    ),
                    tooltip: protocol.active ? 'Desativar' : 'Ativar',
                    onPressed: () async {
                      await ProtocolService.toggleProtocolActive(protocol.id);
                      reload();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Editar',
                    onPressed: () => _openForm(protocol),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Excluir',
                    onPressed: () => _confirmDelete(protocol),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(Protocol? protocol) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProtocolFormScreen(protocol: protocol),
      ),
    );
    reload();
  }

  Future<void> _confirmDelete(Protocol protocol) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir protocolo'),
        content: Text('Tem certeza que deseja excluir "${protocol.displayName}"? Todas as aplicacoes futuras serao removidas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ProtocolService.deleteProtocol(protocol.id);
    reload();
  }

  Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return const Color(0xFF00ACC1);
    }
  }
}