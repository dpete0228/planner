import 'dart:io';
import 'package:planner/Calendar.dart';

Future<void> main() async {
  final calendar = await Calendar.create();

  while (true) {
    // Clear console for cleaner UI
    if (Platform.isWindows) {
      // Works in most terminals on Windows
      stdout.write('\x1B[2J\x1B[0;0H');
    } else {
      // Works for macOS/Linux
      stdout.write('\x1B[2J\x1B[H');
    }

    print('=============================');
    print('         Planner Menu         ');
    print('=============================');
    print('1) View today\'s events');
    print('2) List events for a specific day');
    print('3) Add an event');
    print('4) Remove an event');
    print('5) Exit');
    stdout.write('\nSelect an option (1-5): ');

    final input = stdin.readLineSync()?.trim();

    switch (input) {
      case '1':
        print('\n--- Today\'s Events ---');
        calendar.listEvents(DateTime.now());
        break;

      case '2':
        stdout.write('Enter a date (YYYY-MM-DD): ');
        final dateInput = stdin.readLineSync();
        try {
          final date = DateTime.parse(dateInput!);
          print('\n--- Events on ${date.toLocal()} ---');
          calendar.listEvents(date);
        } catch (e) {
          print('Invalid date format.');
        }
        break;

      case '3':
        print('\n--- Add New Event ---');
        calendar.addEvent();
        break;

      case '4':
        stdout.write('Enter date to remove from (YYYY-MM-DD): ');
        final dateInput = stdin.readLineSync();
        try {
          final date = DateTime.parse(dateInput!);
          print('\n--- Remove Event ---');
          calendar.removeEvent(date);
        } catch (e) {
          print('Invalid date format.');
        }
        break;

      case '5':
        print('\nGoodbye!');
        return;

      default:
        print('Invalid option. Please try again.');
        break;
    }

    // Pause before returning to menu
    stdout.write('\nPress Enter to continue...');
    stdin.readLineSync();
  }
}
