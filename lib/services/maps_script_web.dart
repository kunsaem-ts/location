import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../app/strings.dart';

/// Maps JavaScript API 스크립트를 `<head>`에 삽입하고 로드 완료를 기다린다.
/// 키가 비어 있거나 스크립트 로드에 실패하면 예외를 던진다 (EX-12).
Future<void> loadMapsScript(String apiKey) {
  if (apiKey.isEmpty) {
    return Future.error(StateError(AppStrings.mapKeyMissing));
  }
  final completer = Completer<void>();
  final script = web.HTMLScriptElement()
    ..src = 'https://maps.googleapis.com/maps/api/js'
        '?key=$apiKey&language=ko&region=KR'
    ..async = true
    ..onload = ((web.Event _) => completer.complete()).toJS
    ..onerror = ((web.Event _) =>
        completer.completeError(StateError(AppStrings.mapLoadError))).toJS;
  web.document.head!.appendChild(script);
  return completer.future;
}
