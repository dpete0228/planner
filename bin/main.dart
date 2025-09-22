import 'package:planner/Calendar.dart';
import 'package:planner/Event.dart';


void main() {
  Calendar calendar = Calendar();
  Event event = Event.fromUserInput();
  calendar.addEvent(event);
  calendar.listEvents();
}