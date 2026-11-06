import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models/models.dart';
import '../core/services/application_service.dart';
import '../core/services/storage_service.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => AgendaScreenState();
}

class AgendaScreenState extends State<AgendaScreen> {
  List<ApplicationRecord> _applications = [];
  List<Protocol> _protocols = [];
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
      final apps = await ApplicationService.loadApplications();
      final protocols = await StorageService.loadProtocols();

      // Ordenar por data
      apps.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      if (mounted) {
        setState(() {
          _applications = apps;
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
      appBar: AppBar(title: const Text('Agenda')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _applications.length,
                    itemBuilder: (context, index) {
                      return _buildApplicationCard(theme, _applications[index]);
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
            Icons.calendar_month_outlined,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Agenda vazia',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Crie um protocolo para gerar aplicacoes automaticamente',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(ThemeData theme, ApplicationRecord app) {
    final protocol = _protocols.firstWhere(
      (p) => p.id == app.protocolId,
      orElse: () => _protocols.first,
    );

    final color = _getStatusColor(app.status);
    final statusIcon = _getStatusIcon(app.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    protocol.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('dd/MM/yyyy HH:mm').format(app.scheduledAt)} - ${app.doseValue} ${app.doseUnit}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(statusIcon, color: color, size: 24),
            const SizedBox(width: 8),
            if (app.status == ApplicationStatus.scheduled) ...[
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                tooltip: 'Aplicar',
                onPressed: () => _markApplied(app),
              ),
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.orange),
                tooltip: 'Pular',
                onPressed: () => _markSkipped(app),
              ),
            ] else if (app.status == ApplicationStatus.applied) ...[
              IconButton(
                icon: const Icon(Icons.undo, color: Colors.grey),
                tooltip: 'Desfazer',
                onPressed: () => _undo(app),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applied: return Colors.green;
      case ApplicationStatus.skipped: return Colors.orange;
      case ApplicationStatus.scheduled: return Colors.blue;
    }
  }

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applied: return Icons.check_circle;
      case ApplicationStatus.skipped: return Icons.cancel;
      case ApplicationStatus.scheduled: return Icons.schedule;
    }
  }

  Future<void> _markApplied(ApplicationRecord app) async {
    await ApplicationService.markAsApplied(applicationId: app.id);
    reload();
  }

  Future<void> _markSkipped(ApplicationRecord app) async {
    await ApplicationService.markAsSkipped(applicationId: app.id);
    reload();
  }

  Future<void> _undo(ApplicationRecord app) async {
    await ApplicationService.undoApplication(applicationId: app.id);
    reload();
  }
}