import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app_state.dart';
import 'app/strings.dart';
import 'screens/insecure_context_screen.dart';
import 'screens/main_screen.dart';
import 'screens/permission_denied_screen.dart';
import 'screens/permission_intro_screen.dart';
import 'screens/service_off_screen.dart';
import 'services/connectivity_service.dart';
import 'services/location_service.dart';
import 'services/storage_service.dart';

void main() {
  final storage = StorageService();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(
        LocationService(),
        storage,
        ConnectivityService(storage),
      )..init(),
      child: const LocationCheckApp(),
    ),
  );
}

class LocationCheckApp extends StatelessWidget {
  const LocationCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const _StageRouter(),
    );
  }
}

/// PRD 2.1 화면 흐름: AppStage에 따라 화면을 고른다.
class _StageRouter extends StatelessWidget {
  const _StageRouter();

  @override
  Widget build(BuildContext context) {
    final stage = context.select<AppState, AppStage>((s) => s.stage);
    return switch (stage) {
      AppStage.checking =>
        const Scaffold(body: Center(child: CircularProgressIndicator())),
      AppStage.insecureContext => const InsecureContextScreen(),
      AppStage.permissionIntro => const PermissionIntroScreen(),
      AppStage.permissionDenied => const PermissionDeniedScreen(),
      AppStage.serviceOff => const ServiceOffScreen(),
      AppStage.main => const MainScreen(),
    };
  }
}
