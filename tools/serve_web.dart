// Minimal offline static file server for the built Flutter web bundle.
// Usage: dart run tools/serve_web.dart [rootDir] [port]
// Serves build/web on http://localhost:8080 by default. No packages required.
import 'dart:io';

const _mime = {
  '.html': 'text/html; charset=utf-8',
  '.htm': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.map': 'application/json',
  '.bin': 'application/octet-stream',
};

String _mimeFor(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0) return 'application/octet-stream';
  return _mime[path.substring(dot).toLowerCase()] ?? 'application/octet-stream';
}

Future<void> main(List<String> args) async {
  final root = args.isNotEmpty ? args[0] : 'build/web';
  final port = args.length > 1 ? int.parse(args[1]) : 8080;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('Serving $root at http://localhost:$port');
  await for (final req in server) {
    try {
      var path = req.uri.path;
      if (path == '/' || path.isEmpty) path = '/index.html';
      var file = File('$root$path');
      if (!await file.exists()) {
        // SPA fallback for routes without a file extension.
        if (!path.contains('.')) {
          file = File('$root/index.html');
        } else {
          req.response.statusCode = HttpStatus.notFound;
          await req.response.close();
          continue;
        }
      }
      req.response.headers.set(HttpHeaders.contentTypeHeader, _mimeFor(file.path));
      req.response.headers.set('Cache-Control', 'no-cache');
      await req.response.addStream(file.openRead());
      await req.response.close();
    } catch (_) {
      try {
        req.response.statusCode = HttpStatus.internalServerError;
        await req.response.close();
      } catch (_) {}
    }
  }
}
