import 'dart:io';
import 'package:excel_community/excel_community.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/scan_item.dart';

class ExcelService {
  static Future<String?> exportToExcel(List<ScanItem> items) async {
    if (items.isEmpty) {
      return null;
    }

    try {
      final excel = Excel.createExcel();
      final sheet = excel.tables['Sheet1'];

      if (sheet == null) {
        return null;
      }

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('codigo');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = TextCellValue('tipo');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = TextCellValue('fecha');

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final row = i + 1;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(item.code);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(item.type == ScanType.solapine ? 'solapine' : 'tarjeta');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(DateUtils.formatDate(item.scannedAt));
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'solapines_${DateUtils.getDateFileName()}.xlsx';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      final encoded = excel.encode();
      if (encoded != null) {
        await file.writeAsBytes(encoded);
      }

      return filePath;
    } catch (e) {
      return null;
    }
  }
}