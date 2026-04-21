import 'dart:io';
import 'package:excel_community/excel_community.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/scan_item.dart';

class ExcelService {
  static Future<List<String>> importFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        return [];
      }

      final file = File(filePath);
      if (!await file.exists()) {
        return [];
      }

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        return [];
      }

      final List<String> codes = [];
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null) {
        return [];
      }

      for (var i = 1; i < sheet.maxRows; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i));
        final value = cell.value;
        if (value != null && value.toString().trim().isNotEmpty) {
          codes.add(value.toString().trim());
        }
      }

      return codes;
    } catch (e) {
      return [];
    }
  }

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
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(_formatDate(item.scannedAt));
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/codigos_$timestamp.xlsx';
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

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}