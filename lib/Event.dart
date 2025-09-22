import 'dart:io';

class Event {
  DateTime date;
  String name;
  String description;

  Event({
    required this.date,
    required this.name,
    required this.description,
  });

  Event.fromUserInput()
    : date = DateTime.now(), // temporary initialization
      name = '',
      description = '' {
  stdout.write('Enter event name: ');
  name = stdin.readLineSync() ?? '';

  stdout.write('Enter event description: ');
  description = stdin.readLineSync() ?? '';

  DateTime? parsedDate;
  while (parsedDate == null) {
    stdout.write('Enter event date (YYYY-MM-DD HH:MM): ');
    String? input = stdin.readLineSync();
    try {
      parsedDate = DateTime.parse(input ?? '');
    } catch (e) {
      print('Invalid date format. Please try again.');
    }
  }
  date = parsedDate;
}


  List<String> toCsvRow() {
    return [date.toString(), name, description];
  }

  List<dynamic> fromCsvRow(List<dynamic> row) {
    date = DateTime.parse(row[0]);
    name = row[1].toString();
    description = row[2];
    return [date, name, description];
  }

  String formattedDate() {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}