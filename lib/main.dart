import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Calendar',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 70, 177, 248)),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class Event {
  
  String name;
  String description;

  String start;
  String end;

  Event(this.name, this.description, this.start, this.end);

}

class MyAppState extends ChangeNotifier {
  var events = <Event>[];
  var datestring = "";

  void fillDate() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyyMMdd').format(now);
    datestring = formattedDate;
    print(datestring);
  }

  void fillTimetable() async {
    events = <Event>[];
    final api = Uri.parse('http://170.64.242.255:5000/get_events?date=$datestring');
    final eventsData = await http.read(api);
    final eventsJSON = json.decode(eventsData) as Map<String, dynamic>;
    for (var key in eventsJSON.keys) {
      var eventData = json.decode(eventsJSON[key]) as Map<String, dynamic>;

      String start = '${eventData["start"]["hour"]}:${eventData["start"]["minute"]}';  
      String end = '${eventData["end"]["hour"]}:${eventData["end"]["minute"]}'; 
      print(start);  
      Event event = Event(eventData["name"], eventData["description"], start, end);
      events.add(event);
    }
    events.sort((a, b) => a.start.compareTo(b.start));

    notifyListeners();
  }

  MyAppState() {
    fillDate();
    fillTimetable();
    
  }

}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {

    Widget page;
    switch(selectedIndex) {
      case 0:
        page = TimetablePage();
        break;
      case 1:
        page = SettingsPage();
        break;
      default:
        throw UnimplementedError('No widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 800,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_month),
                      label: Text('Timetable'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}


class SettingsPage extends StatelessWidget {
  
  
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(onPressed: appState.fillTimetable, icon: Icon(Icons.settings), label: Text('Get Timetable'))
        ],
      ),
    );
  }
}


class TimetablePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var date = appState.datestring;
    var events = appState.events;
    final theme = Theme.of(context);

    return Center(
      
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        
        child: ListView(
          
          children: [
            Text('Timetable for $date', style: theme.textTheme.displayMedium),
            for (var event in events)
            Card(
              child: ListTile(
                title: Text('${event.name} from ${event.start} until ${event.end}'),
                subtitle: Text(event.description),
              ),
            )
              
          ]
        ),
      ), 
    );
  }
}
