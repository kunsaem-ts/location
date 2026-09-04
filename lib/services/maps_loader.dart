import '../app/constants.dart';
import 'maps_script_stub.dart'
    if (dart.library.js_interop) 'maps_script_web.dart' as impl;

/// 웹에서 Maps JavaScript API 스크립트를 한 번만 로드한다.
/// Android는 SDK가 네이티브로 로드되므로 즉시 완료된다.
class MapsLoader {
  MapsLoader._();

  static Future<void>? _loading;

  static Future<void> ensureLoaded() =>
      _loading ??= impl.loadMapsScript(AppConstants.webMapsApiKey);
}
