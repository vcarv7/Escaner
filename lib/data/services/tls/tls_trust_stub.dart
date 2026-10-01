import 'package:dio/dio.dart';

/// En web el navegador maneja el TLS con su propio almacen y no admite
/// certificados adicionales desde Dart, asi que no hay nada que hacer.
Future<void> initPlatformTls() async {}

/// En web no se puede forzar la IP: la resolucion la hace el navegador.
/// La API tiene que coincidir con `tls_trust_io.dart` porque el export es
/// condicional y el analizador mira las dos ramas.
void setPlatformAddress(String? address) {}

/// Sin equivalente en web: no hay `HttpClient` propio. Dio usa su adapter por
/// defecto, que en web es el correcto.
HttpClientAdapter? createPlatformAdapter(String baseUrl) => null;