import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/async_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> data = DashboardService().load();
  void reload() => setState(() => data = DashboardService().load());
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('TechFix'),
      actions: [IconButton(onPressed: reload, icon: const Icon(Icons.refresh))],
    ),
    body: AsyncContent(
      future: data,
      retry: reload,
      builder: (stats) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Olá, ${AuthService.instance.user?.name ?? ''}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Text('Acompanhe sua assistência técnica'),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final entry in {
                'Clientes': stats['customers'],
                'Aparelhos': stats['devices'],
                'Ordens abertas': stats['open_orders'],
                'Concluídas': stats['completed_orders'],
              }.entries)
                SizedBox(
                  width: 155,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.value}',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          Text(entry.key),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.goNamed(
              AppRoutes.form,
              pathParameters: {'resource': AppRoutes.orders},
            ),
            icon: const Icon(Icons.add),
            label: const Text('Nova ordem de serviço'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.goNamed(AppRoutes.parts),
            child: const Text('Estoque de peças'),
          ),
          if (AuthService.instance.user?.isAdmin ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: OutlinedButton(
                onPressed: () => context.goNamed(AppRoutes.employees),
                child: const Text('Gerenciar funcionários'),
              ),
            ),
        ],
      ),
    ),
  );
}
