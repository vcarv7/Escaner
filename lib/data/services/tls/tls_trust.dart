/// Confianza TLS para el backend de preview.
///
/// Flutter no usa el stack TLS de Android: las peticiones de Dio salen por el
/// BoringSSL que viene dentro del runtime de Dart, y ese no consulta el
/// `network_security_config` de la app. Por eso la CA corporativa hay que
/// entregarsela a mano.
///
/// En web no existe `SecurityContext`, asi que se usa el stub.
library;

export 'tls_trust_stub.dart'
    if (dart.library.io) 'tls_trust_io.dart';