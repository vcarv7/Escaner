import 'dart:io';
import 'package:excel_community/excel_community.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/scan_item.dart';

Uint8List? _generateExcelBytesSync(List<ScanItem> items) {
  if (items.isEmpty) {
    return null;
  }

  try {
    final excel = Excel.createExcel();
    // Tomar la primera hoja disponible en vez de asumir el nombre 'Sheet1',
    // que puede variar según la versión/configuración de excel_community.
    final sheet = excel.tables.values.firstOrNull;

    if (sheet == null) {
      return null;
    }

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('#');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = TextCellValue('nombre_y_apellidos');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = TextCellValue('solapin');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = TextCellValue('evento');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = TextCellValue('tipo');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0)).value = TextCellValue('fecha');

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final row = i + 1;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = IntCellValue(i + 1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(item.personaNombre ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(item.personaSolapine ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(item.evento?.displayName ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = TextCellValue(item.type == ScanType.solapine ? 'solapine' : 'tarjeta');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = TextCellValue(DateUtils.formatDate(item.scannedAt.toLocal()));
    }

    final encoded = excel.encode();
    if (encoded == null) {
      return null;
    }

    return Uint8List.fromList(encoded);
  } catch (e) {
    return null;
  }
}

class ExcelService {
  static Future<Uint8List?> generateExcelBytes(List<ScanItem> items) async {
    return compute(_generateExcelBytesSync, items);
  }

  static Future<bool> saveExcel(Uint8List bytes, String filePath) async {
    try {
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      return false;
    }
  }
}