import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String location;
  const AppShell({super.key, required this.child, required this.location});
  @override
  Widget build(BuildContext context) {
    const routes = [
      AppRoutes.home,
      AppRoutes.customers,
      AppRoutes.devices,
      AppRoutes.orders,
      AppRoutes.profile,
    ];
    final index = routes.indexWhere((route) => location.startsWith('/$route'));
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => context.goNamed(routes[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.smartphone),
            label: 'Aparelhos',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            label: 'Ordens',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
