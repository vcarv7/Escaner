import 'package:dio/dio.dart';

class AppException implements Exception {
  final AppErrorType type;
  final String message;
  final String? technicalMessage;
  final int? statusCode;

  const AppException({
    required this.type,
    required this.message,
    this.technicalMessage,
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
          technicalMessage: e.message,
        );
      case DioExceptionType.connectionError:
        return AppException(
          type: AppErrorType.noConnection,
          message: 'Sin conexión. Verifica tu red.',
          technicalMessage: e.message,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode != null) {
          return AppException.fromStatusCode(statusCode, e.message);
        }
        return AppException(
          type: AppErrorType.unknown,
          message: 'Error inesperado.',
          technicalMessage: e.message,
        );
      case DioExceptionType.cancel:
        return AppException(
          type: AppErrorType.requestCancelled,
          message: 'Petición cancelada.',
          technicalMessage: e.message,
        );
      case DioExceptionType.unknown:
        return AppException(
          type: AppErrorType.unknownNetwork,
          message: 'Error de red desconocido. Verifica tu conexión.',
          technicalMessage: e.message,
        );
      default:
        return AppException(
          type: AppErrorType.unknown,
          message: 'Error inesperado. Intenta más tarde.',
          technicalMessage: e.message,
        );
    }
  }

  factory AppException.fromStatusCode(int statusCode, [String? message]) {
    switch (statusCode) {
      case >= 500:
        return AppException(
          type: AppErrorType.serverError,
          message: 'Error del servidor. Intenta más tarde.',
          technicalMessage: message,
          statusCode: statusCode,
        );
      case 401:
        return AppException(
          type: AppErrorType.unauthorized,
          message: 'Sesión expirada. Inicia sesión nuevamente.',
          technicalMessage: message,
          statusCode: statusCode,
        );
      case 403:
        return AppException(
          type: AppErrorType.forbidden,
          message: 'Acceso denegado.',
          technicalMessage: message,
          statusCode: statusCode,
        );
      case 404:
        return AppException(
          type: AppErrorType.notFound,
          message: 'Recurso no encontrado.',
          technicalMessage: message,
          statusCode: statusCode,
        );
      case 408:
        return AppException(
          type: AppErrorType.timeout,
          message: 'Tiempo de espera de la petición agotado.',
          technicalMessage: message,
          statusCode: statusCode,
        );
      case 429:
        return AppException(
          type: AppErrorType.tooManyRequests,
          message: 'Demasiadas peticiones. Espera un momento e intenta de nuevo.',
          technicalMessage: message,
          statusCode: statusCode,
        );
      case >= 400:
        return AppException(
          type: AppErrorType.clientError,
          message: 'Error en la petición ($statusCode).',
          technicalMessage: message,
          statusCode: statusCode,
        );
      default:
        return AppException(
          type: AppErrorType.unknown,
          message: 'Error inesperado.',
          technicalMessage: message,
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
    return 'AppException(type: ${type.name}, message: $message, technical: $technicalMessage, statusCode: $statusCode)';
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