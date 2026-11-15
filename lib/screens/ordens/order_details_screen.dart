import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_config.dart';
import '../../core/routes/app_routes.dart';
import '../../models/resource_record.dart';
import '../../services/resource_service.dart';
import '../../widgets/async_content.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int id;
  const OrderDetailsScreen({super.key, required this.id});
  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Future<ResourceRecord> data = const RepairOrderService().get(widget.id);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Detalhes da ordem'),
      leading: IconButton(
        onPressed: () => context.goNamed(AppRoutes.orders),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: AsyncContent(
      future: data,
      retry: () =>
          setState(() => data = const RepairOrderService().get(widget.id)),
      builder: (row) {
        final v = row.values;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(row.label, style: Theme.of(context).textTheme.headlineMedium),
            for (final entry in {
              'Status': ApiConfig.statusLabels[v['status']],
              'Cliente': v['aparelho']?['cliente']?['name'],
              'Aparelho': v['aparelho']?['model'],
              'Problema': v['problem'],
              'Diagnóstico': v['diagnosis'],
              'Valor': 'R\$ ${v['price']}',
              'Responsável': v['assigned_user']?['name'],
              'Observações': v['notes'],
            }.entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.key),
                subtitle: Text('${entry.value ?? '—'}'),
              ),
            FilledButton(
              onPressed: () => context.goNamed(
                AppRoutes.form,
                pathParameters: {'resource': AppRoutes.orders},
                queryParameters: {'id': '${widget.id}'},
              ),
              child: const Text('Editar ordem'),
            ),
            const SizedBox(height: 24),
            Text(
              'Histórico de reparos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final event in (v['history'] as List? ?? []))
              ListTile(
                leading: const Icon(Icons.history),
                title: Text(
                  ApiConfig.statusLabels[event['status']] ??
                      '${event['status']}',
                ),
                subtitle: Text(
                  '${event['created_at']} · ${event['user']?['name'] ?? ''}',
                ),
              ),
          ],
        );
      },
    ),
  );
}
