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
      home: InterfacePage(),
    );
  }
}
