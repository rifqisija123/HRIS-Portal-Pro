import 'dart:io';
import 'dart:convert';

void main() async {
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse('https://raw.githubusercontent.com/guangrei/APIHariLibur_V2/main/calendar.json'));
  final response = await request.close();
  final stringData = await response.transform(utf8.decoder).join();
  File('holiday_full.json').writeAsStringSync(stringData);
  print('done full json');
}
