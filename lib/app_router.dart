import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/routes/app_routes.dart';
import 'core/constants/resource_fields.dart';
import 'services/auth_service.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/shell/app_shell.dart';
import 'screens/resources/resource_list_screen.dart';
import 'screens/resources/resource_form_screen.dart';
import 'screens/ordens/order_details_screen.dart';
import 'screens/perfil/profile_screen.dart';

// Composition lives outside core so core remains independent of screens/services.
final appRouter = GoRouter(
  initialLocation: '/home',
  refreshListenable: AuthService.instance,
  redirect: (context, state) {
    final authPage =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';
    final user = AuthService.instance.user;
    if (user == null) return authPage ? null : '/login';
    if (authPage) return '/home';
    if (!user.isAdmin &&
        (state.matchedLocation == '/users' ||
            state.pathParameters['resource'] == 'users')) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      name: AppRoutes.login,
      builder: (_, _) => const AuthScreen(),
    ),
    GoRoute(
      path: '/register',
      name: AppRoutes.register,
      builder: (_, _) => const AuthScreen(register: true),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: AppRoutes.home,
          builder: (_, _) => const HomeScreen(),
        ),
        GoRoute(
          path: '/perfil',
          name: AppRoutes.profile,
          builder: (_, _) => const ProfileScreen(),
        ),
        for (final resource in ResourceFields.titles.keys)
          GoRoute(
            path: '/$resource',
            name: resource,
            builder: (_, _) =>
                ResourceListScreen(key: ValueKey(resource), resource: resource),
          ),
      ],
    ),
    GoRoute(
      path: '/form/:resource',
      name: AppRoutes.form,
      builder: (context, state) {
        final resource = state.pathParameters['resource']!;
        if (!ResourceFields.fields.containsKey(resource)) {
          return const Scaffold(body: Center(child: Text('Recurso inválido.')));
        }
        final rawId = state.uri.queryParameters['id'];
        final id = int.tryParse(rawId ?? '');
        if (rawId != null && id == null) {
          return const Scaffold(
            body: Center(child: Text('Identificador inválido.')),
          );
        }
        return ResourceFormScreen(resource: resource, id: id);
      },
    ),
    GoRoute(
      path: '/details/:resource',
      name: AppRoutes.details,
      builder: (context, state) {
        final id = int.tryParse(state.uri.queryParameters['id'] ?? '');
        return id == null
            ? const Scaffold(body: Center(child: Text('Ordem inválida.')))
            : OrderDetailsScreen(id: id);
      },
    ),
  ],
  errorBuilder: (_, _) =>
      const Scaffold(body: Center(child: Text('Página não encontrada.'))),
);
