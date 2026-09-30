import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// CA corporativa que firma el certificado del backend de preview.
const String _assetPath = 'assets/certs/ca_corporativa.pem';

/// IP del backend cuando la red no resuelve el hostname.
///
/// El resolver de la WiFi corporativa no conoce los hosts internos, asi que
/// la app conecta contra la IP. No es un rodeo inseguro: el socket se abre
/// contra la IP pero la verificacion del certificado sigue hacerse contra el
/// hostname de `baseUrl` (ver [createPlatformAdapter]), asi que la CA
/// corporativa y el SAN siguen mandando.
///
/// Si el cliente tiene un DNS que resuelve el dominio, alcanza con deixar este
/// valor en `null`: el certificado y el resto del codigo no cambian.
String? _addressOverride;

SecurityContext? _context;

/// Fija la IP a la que se conecta el backend. `null` restaura el DNS normal.
void setPlatformAddress(String? address) {
  _addressOverride = address;
}

/// Carga la CA corporativa y la suma a las raices confiables del sistema.
///
/// Hay que.awaitar esto en `main()` antes de construir el `ApiClient`: el
/// contexto TLS se crea una vez y se comparte con todos los `HttpClient` que
/// arma el adapter de Dio.
Future<void> initPlatformTls() async {
  try {
    final pem = await rootBundle.loadString(_assetPath);
    final context = SecurityContext(withTrustedRoots: true)
      ..setTrustedCertificatesBytes(pem.codeUnits);
    _context = context;
    if (kDebugMode) {
      debugPrint('TLS: CA corporativa cargada desde $_assetPath');
    }
  } catch (e) {
    // Sin la CA el backend de preview no valida, pero el resto de la app
    // sigue funcionando contra cualquier host con certificado publico.
    _context = null;
    if (kDebugMode) {
      debugPrint('TLS: no se pudo cargar la CA corporativa: $e');
    }
  }
}

/// Adapter con la CA corporativa, apuntando a la IP del override.
///
/// El socket se abre contra [_addressOverride] pero `SecureSocket.secure` recibe
/// `url.host` como nombre a verificar: BoringSSL valida el certificado contra
/// `alimentacion-preview.din.uci.cu` y no contra `10.11.2.55`.
///
/// Devuelve `null` si no hay CA, no hay override, o la URL ya es una IP, para
/// que Dio conserve su adapter por defecto.
HttpClientAdapter? createPlatformAdapter(String baseUrl) {
  final context = _context;
  final address = _addressOverride;
  if (context == null || address == null) return null;

  final host = Uri.parse(baseUrl).host;
  if (host.isEmpty || InternetAddress.tryParse(host) != null) return null;

  if (kDebugMode) {
    debugPrint('TLS: conectando a $address verificando el certificado como $host');
  }

  return IOHttpClientAdapter(
    createHttpClient: () => HttpClient(context: context)
      ..connectionFactory = (url, proxyHost, proxyPort) {
        return Future.value(
          ConnectionTask.fromSocket<Socket>(
            Socket.connect(address, url.port).then(
              (socket) => SecureSocket.secure(
                socket,
                host: url.host,
                context: context,
              ),
            ),
            () {},
          ),
        );
      },
  );
}