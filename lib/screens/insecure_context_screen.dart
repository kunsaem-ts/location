import 'package:flutter/material.dart';

import '../app/strings.dart';
import '../widgets/notice_layout.dart';

/// 웹에서 HTTP로 열린 경우 (EX-13). 위치 API 자체가 차단되므로 버튼 없이 안내만 한다.
class InsecureContextScreen extends StatelessWidget {
  const InsecureContextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NoticeLayout(
      icon: Icons.lock_outline,
      title: AppStrings.insecureTitle,
      body: AppStrings.insecureBody,
      actions: [],
    );
  }
}
