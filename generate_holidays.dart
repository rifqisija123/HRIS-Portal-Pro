import 'dart:io';
import 'dart:convert';

void main() {
  final dir = Directory('assets/holidays');
  final files = dir.listSync().where((f) => f.path.endsWith('.json')).toList();
  
  StringBuffer sb = StringBuffer();
  sb.writeln("import '../pages/dashboard_page.dart';"); // For the Holiday class
  sb.writeln("");
  sb.writeln("class HolidayData {");
  sb.writeln("  static final Map<int, List<Holiday>> yearlyHolidays = {");
  
  for (var file in files) {
    final yearStr = file.uri.pathSegments.last.replaceAll('.json', '');
    final year = int.parse(yearStr);
    
    final content = File(file.path).readAsStringSync();
    final List<dynamic> jsonList = jsonDecode(content);
    
    sb.writeln("    $year: [");
    for (var item in jsonList) {
      final dateStr = item['date'] as String;
      final dateParts = dateStr.split('-');
      final y = int.parse(dateParts[0]);
      final m = int.parse(dateParts[1]);
      final d = int.parse(dateParts[2]);
      
      final name = item['name'].replaceAll("'", "\\'");
      final isNational = item['is_national_holiday'] as bool;
      final isCuti = !isNational;
      
      sb.writeln("      Holiday(date: DateTime($y, $m, $d), name: '$name', isCutiBersama: $isCuti),");
    }
    sb.writeln("    ],");
  }
  
  sb.writeln("  };");
  sb.writeln("}");
  
  Directory('lib/data').createSync(recursive: true);
  File('lib/data/holiday_data.dart').writeAsStringSync(sb.toString());
  print('done generating');
}
