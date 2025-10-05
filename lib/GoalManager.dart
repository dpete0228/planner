import 'Goal.dart';
import 'dart:io';
import 'package:csv/csv.dart';

/// The GoalManager class manages a list of Goals objects,
/// providing methods for creating, saving, and loading goals
/// from a local CSV file (`data/indicators.csv`).
/// Each goal represents a measurable target or objective that
/// can be linked to events in the Calendar.
class GoalManager {
  /// The list of all available goals currently in memory.
  List<Goal> availableGoals = [];

  /// The file where all goals (indicators) are stored persistently.
  final File file = File('data/indicators.csv');

  /// Private constructor used internally for controlled creation.
  GoalManager._();

  /// Public default constructor (unused in normal flow).
  /// This exists for flexibility or potential testing purposes.
  GoalManager();

  /// Factory constructor that creates and initializes a [GoalManager] instance.
  /// Loads existing goals from the CSV file, creating a new file if necessary.
  static Future<GoalManager> create() async {
    GoalManager indicatorManager = GoalManager._();
    await indicatorManager.loadFile(); // Load goals from file
    return indicatorManager;
  }

  /// Loads goals from the `indicators.csv` file into memory.
  /// - If the file doesn’t exist, a new empty one is created.
  /// - Each line of the CSV file corresponds to one goal.
  /// - Handles any read/parse errors gracefully.
  Future<void> loadFile() async {
    try {
      // Check if file exists; if not, create an empty one
      if (!file.existsSync()) {
        print('indicators.csv not found. Creating a new one...');
        await file.create(recursive: true);
        await file.writeAsString(''); // Initialize with empty contents
        availableGoals = [];
        return;
      }

      // Read the entire CSV content into a string
      final csvString = await file.readAsString();

      // Convert CSV string into a list of rows (each row = list of dynamic values)
      final rows = const CsvToListConverter().convert(csvString);

      // Convert each row into a Goal object and store in availableGoals
      availableGoals = rows
          .map((row) => Goal(
                name: row[0].toString(),
                description: row[1].toString(),
              ))
          .toList();

    } catch (e) {
      // If any error occurs (file missing, parse error, etc.), handle gracefully
      print('Error reading indicators.csv: $e');
      availableGoals = [];
    }
  }

  /// Saves all currently available goals to the `indicators.csv` file.
  ///
  /// Each goal is converted into a CSV row via [Goal.toCsvRow()].
  /// The entire file is rewritten each time this method is called.
  Future<void> saveFile() async {
    List<List<dynamic>> rows = [];

    // Convert each goal to a list of fields for CSV output
    for (var indicator in availableGoals) {
      rows.add(indicator.toCsvRow());
    }

    // Convert list of rows into a single CSV-formatted string
    String csv = const ListToCsvConverter().convert(rows);

    // Ensure the parent directory exists before saving
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    // Ensure the file itself exists
    if (!await file.exists()) {
      await file.create();
    }

    // Write the CSV data to the file (overwrites existing content)
    await file.writeAsString(csv);
    print("File saved.");
  }

  /// Creates a new goal by prompting the user for input in the terminal.
  /// - Uses [Goal.fromUserInput()] to interactively build a new goal.
  /// - Ensures no duplicate goal names are added.
  /// - Automatically saves the updated goal list to file.
  void createGoal() {
    // Collect goal data interactively
    Goal goal = Goal.fromUserInput();

    // Avoid duplicate goals based on name
    if (!availableGoals.any((i) => i.name == goal.name)) {
      availableGoals.add(goal);
    }

    // Save updated goals to file
    saveFile();
  }
}
