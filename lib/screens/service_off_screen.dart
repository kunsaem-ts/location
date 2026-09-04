import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_state.dart';
import '../app/strings.dart';
import '../widgets/notice_layout.dart';

/// E1. 위치 서비스 OFF 안내 (FR-02, EX-04)
class ServiceOffScreen extends StatelessWidget {
  const ServiceOffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final canOpen = state.canOpenSettings;
    return NoticeLayout(
      icon: Icons.location_off_outlined,
      title: AppStrings.serviceOffTitle,
      body: canOpen
          ? AppStrings.serviceOffBody
          : '${AppStrings.serviceOffBody}\n${AppStrings.serviceOffWebGuide}',
      actions: [
        if (canOpen)
          FilledButton(
            onPressed: state.openLocationSettings,
            child: const Text(AppStrings.openLocationSettings),
          ),
        OutlinedButton(
          onPressed: state.recheck,
          child: const Text(AppStrings.recheck),
        ),
      ],
    );
  }
}
