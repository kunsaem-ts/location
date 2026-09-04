// build/web을 GitHub Pages와 같은 하위 경로(/location/)로 서비스하는 로컬 정적 서버.
// 사용: dart run tool/serve_web.dart [포트=8081] [basePath=/location/]
// 검증용(TASKS.md 8-3). 배포에는 쓰지 않는다.
import 'dart:io';

Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? int.parse(args[0]) : 8081;
  final basePath = args.length > 1 ? args[1] : '/location/';
  final root = Directory('build/web');
  if (!root.existsSync()) {
    stderr.writeln('build/web 이 없습니다. 먼저 tool/build_web.ps1 -BaseHref $basePath 를 실행하세요.');
    exit(1);
  }

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('serving ${root.path} at http://127.0.0.1:$port$basePath');

  await for (final req in server) {
    var path = req.uri.path;
    if (!path.startsWith(basePath)) {
      req.response
        ..statusCode = HttpStatus.notFound
        ..write('not under $basePath')
        ..close();
      continue;
    }
    path = path.substring(basePath.length);
    if (path.isEmpty || path.endsWith('/')) path = '${path}index.html';
    final file = File('${root.path}/$path');
    if (!file.existsSync()) {
      req.response
        ..statusCode = HttpStatus.notFound
        ..close();
      continue;
    }
    req.response.headers.contentType = _contentType(path);
    await req.response.addStream(file.openRead());
    await req.response.close();
  }
}

ContentType _contentType(String path) {
  final ext = path.split('.').last.toLowerCase();
  return switch (ext) {
    'html' => ContentType.html,
    'js' || 'mjs' => ContentType('text', 'javascript', charset: 'utf-8'),
    'json' => ContentType.json,
    'css' => ContentType('text', 'css', charset: 'utf-8'),
    'png' => ContentType('image', 'png'),
    'ico' => ContentType('image', 'x-icon'),
    'wasm' => ContentType('application', 'wasm'),
    'svg' => ContentType('image', 'svg+xml'),
    'woff2' => ContentType('font', 'woff2'),
    'ttf' => ContentType('font', 'ttf'),
    'otf' => ContentType('font', 'otf'),
    _ => ContentType.binary,
  };
}
