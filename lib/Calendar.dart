import 'dart:io';
import 'package:csv/csv.dart';
import 'Event.dart';
import 'GoalManager.dart';

/// The Calendar class manages a collection of Event objects,
/// organized by their date (day-level granularity).

class Calendar {
  /// Stores all events, grouped by their date (ignoring the time portion).
  Map<DateTime, List<Event>> events = {};

  /// Reference to the CSV file that stores all event data.
  final File file = File('data/events.csv');

  /// The [GoalManager] instance responsible for managing goals linked to events.
  late GoalManager goalManager;

  /// Private constructor to enforce creation via the factory method.
  Calendar._();

  /// Asynchronous factory constructor that creates and initializes a Calendar instance.
  /// It sets up the GoalManager, loads existing events from file,
  /// and returns a ready-to-use calendar.
  static Future<Calendar> create() async {
    Calendar calendar = Calendar._();
    calendar.goalManager = await GoalManager.create(); // initialize GoalManager
    await calendar.loadFile(); // load existing events
    return calendar;
  }

  /// Loads events from the CSV file into memory.
  /// If the file doesn't exist, it creates an empty one.
  /// Each line in the CSV represents one event (optionally with a linked goal).
  Future<void> loadFile() async {
    // If file does not exist, create it and return empty event list
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('');
      events = {};
      return;
    }

    // Read the CSV file line-by-line
    var lines = await file.readAsLines();
    for (var line in lines) {
      // Convert a CSV-formatted line into a list of dynamic values
      List<dynamic> row = const CsvToListConverter().convert(line).first;

      // Create a temporary event and populate it from the CSV row
      var event = Event(date: DateTime.now(), name: '', description: '');
      event.fromCsvRow(row);

      // Normalize the date to remove the time component (key by day)
      final dateKey = DateTime(event.date.year, event.date.month, event.date.day);

      // Add event to the map, initializing list if necessary
      events.putIfAbsent(dateKey, () => []).add(event);
    }
  }

  /// Saves all in-memory events to the CSV file.
  /// Converts each [Event] into a list of values and writes them as CSV.
  Future<void> saveFile() async {
    List<List<dynamic>> rows = [];

    // Convert each event into a CSV row
    for (var dayEvents in events.values) {
      for (var event in dayEvents) {
        rows.add(event.toCsvRow());
      }
    }

    // Convert rows to CSV text
    String csv = const ListToCsvConverter().convert(rows);

    // Ensure parent directories exist before writing
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    // Write data to file (overwrites existing contents)
    await file.writeAsString(csv);
    print("File saved.");
  }

  /// Prompts the user to create a new event interactively via the terminal.
  ///  Includes:
  /// - Name and description input.
  /// - Date validation loop.
  /// - Optional goal linking (either existing or new).
  void addEvent() {
    // Collect basic event info
    stdout.write('Enter event name: ');
    var name = stdin.readLineSync() ?? '';

    stdout.write('Enter event description: ');
    var description = stdin.readLineSync() ?? '';

    // Parse and validate the date input
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

    final date = parsedDate;
    // Normalize to date key (ignore time)
    final dateKey = DateTime(date.year, date.month, date.day);

    // Ask user if they want to link a goal
    stdout.write('Do you want to link a goal to this one? (Yes/No): ');
    String? input = stdin.readLineSync();
    input = input?.trim().toLowerCase();

    var linkedGoal;

    // Handle goal linking
    if (input == 'yes' || input == 'y') {
      print("\nAvailable goals:");
      for (var i = 0; i < goalManager.availableGoals.length; i++) {
        print("${i + 1}) ${goalManager.availableGoals[i].name}");
      }
      print("${goalManager.availableGoals.length + 1}) Create New Goal");

      bool validChoice = false;
      while (!validChoice) {
        stdout.write("Which goal do you want? ");
        String? choiceInput = stdin.readLineSync();
        int? choice = int.tryParse(choiceInput ?? '');

        // Validate choice
        if (choice == null ||
            choice < 1 ||
            choice > goalManager.availableGoals.length + 1) {
          print("Invalid choice. Try again.");
          continue;
        }

        if (choice == goalManager.availableGoals.length + 1) {
          // Create and link a new goal
          goalManager.createGoal();
          linkedGoal = goalManager.availableGoals.last;
        } else {
          // Use an existing goal
          linkedGoal = goalManager.availableGoals[choice - 1];
        }

        validChoice = true;
      }

      print('Goal linked.');
    } else {
      print('No goal linked.');
      linkedGoal = null;
    }

    // Create the event with optional goal
    Event tempEvent = Event(
      date: date,
      name: name,
      description: description,
      linkedGoal: linkedGoal,
    );

    // Add event to the map
    events.putIfAbsent(dateKey, () => []).add(tempEvent);

    // Save changes to file
    saveFile();
  }

  /// Removes an event occurring on a specific date.
  /// Lists all events for that day, lets the user choose one,
  /// and then deletes it from memory and from file.
  void removeEvent(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);

    // Check if any events exist for that day
    if (!events.containsKey(dateKey) || events[dateKey]!.isEmpty) {
      print("No events found for that day.");
      return;
    }

    var dayEvents = events[dateKey]!;

    // Display available events to remove
    for (var i = 0; i < dayEvents.length; i++) {
      print('${i + 1}) ${dayEvents[i].name}');
    }

    stdout.write('Select an event to remove: ');
    String? input = stdin.readLineSync();
    int index = int.tryParse(input ?? '') ?? -1;

    // Validate user selection
    if (index < 1 || index > dayEvents.length) {
      print('Invalid selection.');
      return;
    }

    // Remove the selected event
    dayEvents.removeAt(index - 1);

    // If no events left for that date, remove the key entirely
    if (dayEvents.isEmpty) events.remove(dateKey);

    // Save changes
    saveFile();
    print("Event removed.");
  }

  /// Lists all events occurring on a specific date.
  /// Displays the name, time, and linked goal (if any).
  void listEvents(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);

    // Handle case when no events exist for given date
    if (!events.containsKey(dateKey) || events[dateKey]!.isEmpty) {
      print('No events found for ${dateKey.toLocal()}.');
      return;
    }

    // Print details for each event on that date
    for (var event in events[dateKey]!) {
      final goalInfo = event.linkedGoal != null
          ? ' (Goal: ${event.linkedGoal!.name})'
          : '';
      print('${event.formattedDate()}: ${event.name}$goalInfo');
    }
  }
}
