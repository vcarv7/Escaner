import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:dio/dio.dart';

final Logger log = Logger('Escaner');

void initAppLogger() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    final buffer = StringBuffer();
    buffer.write('${record.time.toLocal()} [${record.level.name}] ');
    buffer.write('${record.loggerName}: ${record.message}');
    if (record.error != null) {
      buffer.write('\n  Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      buffer.write('\n  Stack: ${record.stackTrace}');
    }
    if (Platform.isAndroid || Platform.isIOS) {
      debugPrint(buffer.toString());
    } else {
      debugPrint(buffer.toString());
    }
  });
}

extension LoggerExt on Logger {
  void logRequest(String method, Uri uri, {Object? data}) {
    if (isLoggable(Level.FINE)) {
      fine('REQUEST[$method] $uri${data != null ? '\n   Data: $data' : ''}');
    }
  }

  void logResponse(int statusCode, Uri uri) {
    if (isLoggable(Level.FINE)) {
      fine('RESPONSE[$statusCode] $uri');
    }
  }

  void logError(Uri uri, DioException err) {
    if (isLoggable(Level.SEVERE)) {
      severe('ERROR[${err.response?.statusCode}] $uri: ${err.message}');
      if (err.response?.data != null) {
        severe('   Response: ${err.response!.data}');
      }
    }
  }
}