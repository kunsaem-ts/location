import 'package:flutter_test/flutter_test.dart';
import 'package:location_check/services/web_context.dart';

void main() {
  group('웹 보안 컨텍스트 판정 (EX-13)', () {
    test('HTTPS면 정상', () {
      expect(
        isInsecureWebContext(Uri.parse('https://user.github.io/repo/'), isWeb: true),
        isFalse,
      );
    });

    test('HTTP + 외부 호스트면 차단', () {
      expect(
        isInsecureWebContext(Uri.parse('http://user.github.io/repo/'), isWeb: true),
        isTrue,
      );
      expect(
        isInsecureWebContext(Uri.parse('http://192.168.0.10:8080/'), isWeb: true),
        isTrue,
      );
    });

    test('HTTP라도 localhost·127.0.0.1은 허용 (개발용)', () {
      expect(isInsecureWebContext(Uri.parse('http://localhost:8080/'), isWeb: true), isFalse);
      expect(isInsecureWebContext(Uri.parse('http://127.0.0.1:8080/'), isWeb: true), isFalse);
    });

    test('웹이 아니면 항상 정상', () {
      expect(isInsecureWebContext(Uri.parse('http://anything/'), isWeb: false), isFalse);
    });
  });
}
