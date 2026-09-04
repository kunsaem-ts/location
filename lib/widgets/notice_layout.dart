import 'package:flutter/material.dart';

import '../app/strings.dart';

/// S1/E1/E2 안내 화면 공통 레이아웃: 아이콘, 제목, 본문, 버튼들.
class NoticeLayout extends StatelessWidget {
  const NoticeLayout({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actions,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(body, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Wrap(spacing: 12, runSpacing: 8, children: actions),
            ],
          ),
        ),
      ),
    );
  }
}
