class AppDeepLink {
  final String joinToken;

  const AppDeepLink._(this.joinToken);

  static final RegExp _joinTokenPattern = RegExp(r'^[A-HJ-NP-Z2-9]{6}$');

  static AppDeepLink? parse(Uri uri) {
    if (uri.scheme.toLowerCase() != 'hiddengems' ||
        uri.host.toLowerCase() != 'join') {
      return null;
    }

    final rawToken = uri.queryParameters['token'] ??
        (uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null);
    final token = rawToken?.trim().toUpperCase();
    if (token == null || !_joinTokenPattern.hasMatch(token)) return null;
    return AppDeepLink._(token);
  }
}
