// dart:html is deprecated in favor of package:web + dart:js_interop, but
// that replacement is considerably more verbose for a single event
// listener like this -- not worth it here.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:go_router/go_router.dart';

/// Works around a go_router/Flutter-web gap: when the browser's URL
/// fragment changes via a mechanism go_router didn't initiate itself (e.g.
/// navigating to a bookmarked deep link in a tab that's already showing the
/// app), go_router's `redirect` callback DOES correctly re-evaluate and
/// resolve to the right route internally -- verified directly -- but the
/// visible address bar is never updated to match, leaving it showing the
/// original (blocked) URL while a different screen is actually rendered.
/// This forces the address bar back in sync with whatever go_router
/// actually resolved to, once it's had a moment to settle.
void syncRouterWithExternalHashChanges(GoRouter router) {
  html.window.onHashChange.listen((_) async {
    final requestedPath = html.window.location.hash.replaceFirst('#', '');
    if (requestedPath.isEmpty) return;

    // Supabase auth callbacks (invite, password recovery, magic link) arrive
    // as URL fragments containing access_token. Don't treat them as router
    // paths -- the Supabase SDK picks them up automatically.
    if (requestedPath.contains('access_token=') ||
        requestedPath.contains('type=invite') ||
        requestedPath.contains('type=recovery') ||
        requestedPath.contains('type=magiclink')) {
      return;
    }

    router.go(requestedPath);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final resolvedPath = router.routerDelegate.currentConfiguration.uri.toString();
    final currentHash = html.window.location.hash.replaceFirst('#', '');
    if (currentHash != resolvedPath) {
      html.window.location.hash = resolvedPath;
    }
  });
}
