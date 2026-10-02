import 'package:dio/dio.dart';

class AppException implements Exception {
  final AppErrorType type;
  final String message;
  final int? statusCode;

  const AppException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  factory AppException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return AppException(
          type: AppErrorType.timeout,
          message: 'Tiempo de espera agotado. Verifica tu conexión.',
        );
      case DioExceptionType.connectionError:
        return AppException(
          type: AppErrorType.noConnection,
          message: 'Sin conexión. Verifica tu red.',
        );
      case DioExceptionType.badCertificate:
        return AppException(
          type: AppErrorType.badCertificate,
          message: 'El certificado del servidor no es confiable en esta red',
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode != null) {
          return AppException.fromStatusCode(statusCode);
        }
        return AppException(
          type: AppErrorType.unknown,
          message: 'Error inesperado.',
        );
      case DioExceptionType.cancel:
        return AppException(
          type: AppErrorType.requestCancelled,
          message: 'Petición cancelada.',
        );
      case DioExceptionType.unknown:
        return AppException(
          type: AppErrorType.unknownNetwork,
          message: 'Error de red desconocido. Verifica tu conexión.',
        );
      default:
        return AppException(
          type: AppErrorType.unknown,
          message: 'Error inesperado. Intenta más tarde.',
        );
    }
  }

  factory AppException.fromStatusCode(int statusCode) {
    switch (statusCode) {
      case >= 500:
        return AppException(
          type: AppErrorType.serverError,
          message: 'Error del servidor. Intenta más tarde.',
          statusCode: statusCode,
        );
      case 401:
        return AppException(
          type: AppErrorType.unauthorized,
          message: 'Sesión expirada. Inicia sesión nuevamente.',
          statusCode: statusCode,
        );
      case 403:
        return AppException(
          type: AppErrorType.forbidden,
          message: 'Acceso denegado.',
          statusCode: statusCode,
        );
      case 404:
        return AppException(
          type: AppErrorType.notFound,
          message: 'Recurso no encontrado.',
          statusCode: statusCode,
        );
      case 408:
        return AppException(
          type: AppErrorType.timeout,
          message: 'Tiempo de espera de la petición agotado.',
          statusCode: statusCode,
        );
      case 429:
        return AppException(
          type: AppErrorType.tooManyRequests,
          message: 'Demasiadas peticiones. Espera un momento e intenta de nuevo.',
          statusCode: statusCode,
        );
      case >= 400:
        return AppException(
          type: AppErrorType.clientError,
          message: 'Error en la petición ($statusCode).',
          statusCode: statusCode,
        );
      default:
        return AppException(
          type: AppErrorType.unknown,
          message: 'Error inesperado.',
          statusCode: statusCode,
        );
    }
  }

  factory AppException.timeout([String? message]) {
    return AppException(
      type: AppErrorType.timeout,
      message: message ?? 'Tiempo de espera agotado. Verifica tu conexión.',
    );
  }

  factory AppException.noConnection([String? message]) {
    return AppException(
      type: AppErrorType.noConnection,
      message: message ?? 'Sin conexión. Verifica tu red.',
    );
  }

  @override
  String toString() {
    return 'AppException(type: ${type.name}, message: $message, statusCode: $statusCode)';
  }
}

enum AppErrorType {
  timeout,
  noConnection,
  serverError,
  clientError,
  unauthorized,
  forbidden,
  notFound,
  badCertificate,
  tooManyRedirects,
  requestCancelled,
  tooManyRequests,
  unknownNetwork,
  unknown,
}
