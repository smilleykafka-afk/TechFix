import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'app_router.dart';

class TechFixApp extends StatelessWidget {
  const TechFixApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'TechFix',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    routerConfig: appRouter,
  );
}
