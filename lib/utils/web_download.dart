import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

class WebDownload {
  WebDownload._();

  static void descargarBytes({
    required Uint8List bytes,
    required String nombreArchivo,
    required String mimeType,
  }) {
    final partes = <web.BlobPart>[
      bytes.toJS,
    ].toJS;

    final blob = web.Blob(
      partes,
      web.BlobPropertyBag(type: mimeType),
    );

    final url = web.URL.createObjectURL(blob);

    final enlace = web.HTMLAnchorElement()
      ..href = url
      ..download = nombreArchivo;

    enlace.click();
    web.URL.revokeObjectURL(url);
  }
}
