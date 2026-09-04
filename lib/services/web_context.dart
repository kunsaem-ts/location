/// 웹에서 위치 API는 보안 컨텍스트(HTTPS 또는 localhost)에서만 동작한다 (EX-13).
/// HTTP로 열렸으면 true. 웹이 아니면 항상 false.
bool isInsecureWebContext(Uri uri, {required bool isWeb}) {
  if (!isWeb) return false;
  if (uri.scheme == 'https') return false;
  const localHosts = {'localhost', '127.0.0.1', '::1', '[::1]'};
  return !localHosts.contains(uri.host);
}
