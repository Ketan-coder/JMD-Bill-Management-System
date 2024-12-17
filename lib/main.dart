import 'package:flutter/material.dart';
import 'package:kenan/database/database_service.dart';
import 'package:kenan/screens/nav_bar.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database
  await DatabaseService().database;
  
  // Fetch and update the database with the JSON data
  await DatabaseService()
      .loadAndUpdateDatabase('assets/dummy_data.json');

  // Print the contents of the database for debugging
  await DatabaseService().printDatabaseContents();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: 'Roboto',
        primaryColor: Colors.blue[300],
        primaryColorDark: Colors.blue[300],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.blue[300],
          secondary: Colors.deepPurple[300],
          onError: Colors.red[800],
          tertiary: Colors.blue,
          surface: Colors.black,
          background: Colors.white,
          shadow: Colors.grey[100],
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontFamily: 'Roboto',
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Roboto',
          ),
          bodySmall: TextStyle(
            fontFamily: 'Roboto',
          ),
        ),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.blue[300],
          secondary: Colors.deepPurple[800],
          onError: Colors.red[800],
          tertiary: Colors.white,
          surface: Colors.white,
          background: Colors.black,
          shadow: Colors.grey[800],
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const NavBar(),
    );
  }
}
