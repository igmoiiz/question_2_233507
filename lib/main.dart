import 'package:flutter/material.dart';
import 'package:question_2_233507/view/interface.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "PETA",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF00B894),
          secondary: Color(0xFF00CEC9),
          background: Color(0xFF222831),
          surface: Color(0xFF393E46),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: Colors.white,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: Color(0xFF222831),
        cardColor: Color(0xFF393E46),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF222831),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Color(0xFF00B894),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00B894),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF393E46),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          labelStyle: TextStyle(color: Colors.white70),
          iconColor: Color(0xFF00CEC9),
        ),
      ),
      home: InterfacePage(),
    );
  }
}
