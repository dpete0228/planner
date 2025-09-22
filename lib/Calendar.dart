import 'dart:io';
import 'package:csv/csv.dart';
import 'Event.dart';

class Calendar {
  List<Event> events = [];
  final File file = File('data/events.csv');
  
  Calendar() {
  loadFile();
  }
  void loadFile() async {
    var lines = await file.readAsLines();
    for (var line in lines) {
      List<dynamic> row = const CsvToListConverter().convert(line).first;
      Event event = Event(date: DateTime.now(), name: '', description: '');
      event.fromCsvRow(row);
      events.add(event);
    }
  }

  Future<void> saveFile() async {
  List<List<dynamic>> rows = [];

  for (var event in events) {
    rows.add(event.toCsvRow());
  }

  String csv = const ListToCsvConverter().convert(rows);

  // Ensure folder exists
  if (!await file.parent.exists()) {
    await file.parent.create(recursive: true);
  }

  // Create file if missing
  if (!await file.exists()) {
    await file.create(); //
  }

  await file.writeAsString(csv);
  print("File saved.");
}


  void addEvent(Event event) {
    events.add(event);
    saveFile();
  }

  void removeEvent() {
    for (var i = 0; i < events.length; i++) {
      print('${i+1}) ${events[i].name}');
    }
    stdout.write('Select an event to remove: ');
    String? input = stdin.readLineSync();
    int index = int.tryParse(input ?? '') ?? -1;
    if (index < 1 || index > events.length) {
      print('Invalid selection.');
      return;
    }
    events.removeAt(index);
    saveFile();
    print("Event removed.");
  }

  void listEvents() {
    if (events.isEmpty) {
      print('No events found.');
      return;
    }
    for (var event in events) {
      print('${event.formattedDate()}: ${event.name}');
    }
  }

}