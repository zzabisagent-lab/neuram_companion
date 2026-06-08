import 'package:flutter/material.dart';
import 'engine/dart_engine.dart';
import 'engine/persistence.dart';
import 'ui/home_page.dart';

void main() => runApp(const NeuramApp());

class NeuramApp extends StatefulWidget {
  const NeuramApp({super.key});
  @override
  State<NeuramApp> createState() => _NeuramAppState();
}

class _NeuramAppState extends State<NeuramApp> with WidgetsBindingObserver {
  late final DartNeuramEngine engine;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    engine = DartNeuramEngine(Persistence());
    // load()는 HomePage.initState()에서 호출
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // 재개 시 tick()이 Lazy로 방치 시간을 자동 반영
    // 일시정지·종료 시 연결체 저장
    if (s == AppLifecycleState.paused ||
        s == AppLifecycleState.detached) {
      engine.save();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    engine.save();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuRAM Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A14),
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          secondary: Colors.tealAccent,
        ),
      ),
      home: HomePage(engine: engine),
    );
  }
}
