import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_state.dart';
import '../app/strings.dart';
import '../widgets/notice_layout.dart';

/// S1. 권한 안내 화면 (FR-01)
class PermissionIntroScreen extends StatelessWidget {
  const PermissionIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return NoticeLayout(
      icon: Icons.location_on_outlined,
      title: AppStrings.permissionIntroTitle,
      body: AppStrings.permissionIntroBody,
      actions: [
        FilledButton(
          onPressed: state.requestPermission,
          child: const Text(AppStrings.permissionIntroButton),
        ),
      ],
    );
  }
}
