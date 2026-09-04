import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_state.dart';
import '../app/strings.dart';
import '../widgets/notice_layout.dart';

/// E2. 권한 거부 안내. 일시 거부는 [다시 요청], 영구 거부는 [앱 설정 열기] (FR-11, EX-02, EX-03)
class PermissionDeniedScreen extends StatelessWidget {
  const PermissionDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final forever = state.permissionDeniedForever;
    final canOpen = state.canOpenSettings;

    final String body;
    if (!forever) {
      body = AppStrings.permissionDeniedBody;
    } else if (canOpen) {
      body = AppStrings.permissionDeniedForeverBody;
    } else {
      body = AppStrings.permissionDeniedWebGuide;
    }

    return NoticeLayout(
      icon: Icons.block_outlined,
      title: AppStrings.permissionDeniedTitle,
      body: body,
      actions: [
        if (!forever)
          FilledButton(
            onPressed: state.requestPermission,
            child: const Text(AppStrings.requestAgain),
          )
        else if (canOpen)
          FilledButton(
            onPressed: state.openAppSettings,
            child: const Text(AppStrings.openAppSettings),
          ),
        OutlinedButton(
          onPressed: state.recheck,
          child: const Text(AppStrings.recheck),
        ),
      ],
    );
  }
}
