import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

const pastelRed = Color(0xFFFFC1C1);
const pastelBlue = Color(0xFFC1E1FF);
const pastelGreen = Color(0xFFC1FFD7);
const pastelYellow = Color(0xFFFFFFC1);
const pastelPurple = Color(0xFFE1C1FF);
const pastelAccent = Color(0xFFDCCEF9);
const pastelBackground = Color(0xFFF8F6FF);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);
  await Hive.openBox('game_history');
  await Hive.openBox('game_summary');

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: pastelBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: pastelAccent,
          elevation: 2,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        textTheme: TextTheme(bodyMedium: TextStyle(fontSize: 18)),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: pastelAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ),
      home: HomeScreen(),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Finger Flex Game"), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Game Instructions",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                "- Each finger is assigned a color.\n"
                "- When a colored ball appears, the matching finger's vibration motor activates.\n"
                "- Close the corresponding finger to remove it.\n"
                "- If any color accumulates 10 balls, the game ends.\n"
                "- React fast to keep playing!",
                style: TextStyle(fontSize: 18, height: 1.5),
              ),
              SizedBox(height: 24),
              Text(
                "Finger - Ball Color Mapping",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Column(
                children: List.generate(5, (i) {
                  final colors = [
                    pastelRed,
                    pastelBlue,
                    pastelGreen,
                    pastelYellow,
                    pastelPurple,
                  ];
                  final fingerNames = [
                    "Thumb",
                    "Index Finger",
                    "Middle Finger",
                    "Ring Finger",
                    "Little Finger",
                  ];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        margin: EdgeInsets.only(right: 12, bottom: 8),
                        decoration: BoxDecoration(
                          color: colors[i],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black54),
                        ),
                      ),
                      Text("${fingerNames[i]}", style: TextStyle(fontSize: 18)),
                    ],
                  );
                }),
              ),
              SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        int? repetitions = await showDialog<int>(
                          context: context,
                          builder: (context) {
                            TextEditingController controller =
                                TextEditingController();
                            return AlertDialog(
                              title: Text("Therapy Repetitions"),
                              content: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "Enter number of repetitions",
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    int? value = int.tryParse(
                                      controller.text.trim(),
                                    );
                                    Navigator.of(context).pop(value);
                                  },
                                  child: Text("Start"),
                                ),
                              ],
                            );
                          },
                        );

                        if (repetitions != null && repetitions > 0) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      GameScreen(repetitionTarget: repetitions),
                            ),
                          );
                        }
                      },
                      child: Text("Play Game", style: TextStyle(fontSize: 24)),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameHistoryScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Game History",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  final int repetitionTarget;
  GameScreen({required this.repetitionTarget});
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late IOWebSocketChannel channel;
  List<FallingBlock> blocks = [];
  bool isGameOver = false;
  List<int> accumulatedBalls = List.filled(5, 0);
  late Timer blockSpawnTimer;
  late AnimationController gameLoop;
  List<int> flexValues = List.filled(5, 0);
  List<Color> colors = [
    pastelRed,
    pastelBlue,
    pastelGreen,
    pastelYellow,
    pastelPurple,
  ];
  List<List<int>> reactionTimesByFinger = List.generate(5, (_) => []);
  List<int> flexThresholds = [168, 150, 175, 150, 238];
  int dropCount = 0;
  final int maxDrops = 10;
  int currentColorIndex = 0;
  int blocksRemovedCount = 0;
  List<int> dropsPerColor = List.filled(5, 0);

  void safeSend(String message) {
    try {
      channel.sink.add(message);
    } catch (e) {
      print("⚠️ Error sending message: $message - $e");
    }
  }

  @override
  void initState() {
    super.initState();
    connectWebSocket();
    startGame();
  }

  void connectWebSocket() {
    channel = IOWebSocketChannel.connect("ws://192.168.4.1:8888");
    print("WebSocket connected");

    channel.stream.listen((message) {
      if (message.startsWith("FLEX:")) {
        final data = message.replaceFirst("FLEX:", "").trim();
        final values = data.split(" ");
        if (values.length >= 5) {
          final updatedFlexValues = List<int>.generate(
            5,
            (i) => int.tryParse(values[i])?.clamp(0, 1023) ?? 0,
          );
          if (mounted) {
            setState(() {
              for (int i = 0; i < 5; i++) {
                flexValues[i] = updatedFlexValues[i];
              }
            });
            for (int i = 0; i < 5; i++) {
              if (flexValues[i] > flexThresholds[i]) {
                removeBlocks(i);
              }
            }
          }
        }
      }
    }, onError: (error) => print("WebSocket Error: $error"));
  }

  void startGame() {
    Hive.box('game_history').clear();
    setState(() {
      isGameOver = false;
      blocks.clear();
      accumulatedBalls = List.filled(5, 0);
      reactionTimesByFinger = List.generate(5, (_) => []);
      dropCount = 0;
      currentColorIndex = 0;
    });

    blockSpawnTimer = Timer.periodic(Duration(seconds: 6), (timer) {
      if (isGameOver) {
        timer.cancel();
        return;
      }
      if (dropsPerColor.every((count) => count >= widget.repetitionTarget)) {
        setState(() => isGameOver = true);
        stopGame();
        timer.cancel();
        return;
      }
      int attempts = 0;
      while (dropsPerColor[currentColorIndex] >= widget.repetitionTarget &&
          attempts < 5) {
        currentColorIndex = (currentColorIndex + 1) % 5;
        attempts++;
      }
      if (dropsPerColor[currentColorIndex] < widget.repetitionTarget) {
        var block = FallingBlock(x: 0.0, colorIndex: currentColorIndex);
        setState(() {
          blocks.add(block);
        });
        safeSend("VIBRATE:$currentColorIndex");
        dropsPerColor[currentColorIndex]++;
        currentColorIndex = (currentColorIndex + 1) % 5;
      }
    });

    gameLoop =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100))
          ..addListener(updateGame)
          ..repeat();
  }

  void updateGame() {
    if (!isGameOver) {
      setState(() {
        for (var block in blocks) {
          block.y += 0.003;
        }
        for (var block in blocks) {
          if (block.y >= 0.8 && !block.counted) {
            accumulatedBalls[block.colorIndex]++;
            block.counted = true;
            if (accumulatedBalls[block.colorIndex] >= 10) {
              isGameOver = true;
              stopGame();
              safeSend("GAME_OVER");
              break;
            }
          }
          if (block.y >= 0.9) {
            block.y = 0.9;
          }
        }
      });
    }
  }

  void removeBlocks(int colorIndex) {
    final now = DateTime.now();
    setState(() {
      blocks.removeWhere((block) {
        if (block.colorIndex == colorIndex) {
          final reaction = now.difference(block.spawnTime).inMilliseconds;
          reactionTimesByFinger[colorIndex].add(reaction);
          blocksRemovedCount++;
          Hive.box('game_history').add({
            'timestamp': now.toIso8601String(),
            'flexValues': List.from(flexValues),
            'finger': colorIndex,
            'reactionTimeMs': reaction,
          });
          return true;
        }
        return false;
      });
    });
    safeSend("REMOVE:$colorIndex");
  }

  void stopGame() {
    blockSpawnTimer.cancel();
    gameLoop.stop();
    final now = DateTime.now();
    int totalReactions = 0;
    int totalTimes = 0;
    int bestFinger = 0;
    double bestFingerAvg = double.infinity;
    for (int i = 0; i < 5; i++) {
      final reactions = reactionTimesByFinger[i];
      if (reactions.isNotEmpty) {
        final avg = reactions.reduce((a, b) => a + b) / reactions.length;
        totalReactions += reactions.length;
        totalTimes += reactions.reduce((a, b) => a + b);
        if (avg < bestFingerAvg) {
          bestFingerAvg = avg;
          bestFinger = i;
        }
      }
    }
    final gameSummary = {
      'timestamp': now.toIso8601String(),
      'blocksRemoved': totalReactions,
      'avgReactionTime':
          totalReactions > 0
              ? (totalTimes / totalReactions).toStringAsFixed(1)
              : "N/A",
      'bestFinger': bestFinger + 1,
      'bestFingerAvg':
          bestFingerAvg == double.infinity
              ? "N/A"
              : bestFingerAvg.toStringAsFixed(1),
    };
    Hive.box('game_summary').add(gameSummary);
  }

  @override
  void dispose() {
    if (blockSpawnTimer.isActive) blockSpawnTimer.cancel();
    gameLoop.dispose();
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pastelBackground,
      body: Stack(
        children: [
          for (var block in blocks)
            Positioned(
              left: (MediaQuery.of(context).size.width / 2) + (block.x * 150),
              top: (block.y * MediaQuery.of(context).size.height),
              child: Icon(
                Icons.circle,
                size: 50,
                color: colors[block.colorIndex],
              ),
            ),
          Positioned(
            top: 50,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(5, (i) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Finger ${i + 1}: ${flexValues[i]} / ${flexThresholds[i]}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            flexValues[i] > flexThresholds[i]
                                ? Colors.green
                                : Colors.red,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      width: 180,
                      child: LinearProgressIndicator(
                        value: (flexValues[i] / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          flexValues[i] > flexThresholds[i]
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                );
              }),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black26,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  "Accumulated Balls: ${accumulatedBalls.join(" / ")}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          if (isGameOver)
            Center(
              child: Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Game Over",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pastelAccent,
                        padding: EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameAnalysisScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "View Game Analysis",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FallingBlock {
  double x;
  double y = -1.0;
  int colorIndex;
  bool counted = false;
  DateTime spawnTime;

  FallingBlock({required this.x, required this.colorIndex})
    : spawnTime = DateTime.now();
}

class GameAnalysisScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gameHistoryBox = Hive.box('game_history');
    final history = gameHistoryBox.values.toList();

    List<int> fingerUsage = List.filled(5, 0);
    List<List<int>> fingerReactionTimes = List.generate(5, (_) => []);
    List<int> bestReactionTimes = List.filled(5, 999999);

    for (var entry in history) {
      if (entry is Map) {
        int? finger = entry['finger'];
        int? reaction = entry['reactionTimeMs'];

        if (finger != null && reaction != null) {
          fingerUsage[finger]++;
          fingerReactionTimes[finger].add(reaction);

          if (reaction < bestReactionTimes[finger]) {
            bestReactionTimes[finger] = reaction;
          }
        }
      }
    }

    final pastelFingerColors = [
      pastelRed,
      pastelBlue,
      pastelGreen,
      pastelYellow,
      pastelPurple,
    ];

    final fingerLabels = ["Thumb", "Index", "Middle", "Ring", "Little"];

    return Scaffold(
      appBar: AppBar(title: Text("Session Summary")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "How Each Finger Performed",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            for (int i = 0; i < 5; i++)
              Card(
                color: pastelBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: pastelFingerColors[i],
                    child: Text(fingerLabels[i][0]),
                  ),
                  title: Text(
                    fingerLabels[i],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Used: ${fingerUsage[i]} times"),
                        Text(
                          "Average Reaction: ${fingerReactionTimes[i].isEmpty ? 'N/A' : (fingerReactionTimes[i].reduce((a, b) => a + b) / fingerReactionTimes[i].length).toStringAsFixed(1)} ms",
                        ),
                        Text(
                          "Fastest Reaction: ${bestReactionTimes[i] == 999999 ? 'N/A' : '${bestReactionTimes[i]} ms'}",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class GameHistoryScreen extends StatefulWidget {
  @override
  _GameHistoryScreenState createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen> {
  List<Map> summaries = [];

  @override
  void initState() {
    super.initState();
    final summaryBox = Hive.box('game_summary');
    summaries = summaryBox.values.toList().reversed.cast<Map>().toList();
  }

  void _exportAndClear(Box box, String boxName) async {
    final directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists()) await directory.create(recursive: true);
    final file = File('${directory.path}/$boxName.csv');

    List<List<dynamic>> rows = [];
    for (var entry in box.values) {
      if (entry is Map) {
        if (rows.isEmpty) rows.add(entry.keys.toList());
        rows.add(entry.values.toList());
      }
    }

    final csvString = const ListToCsvConverter().convert(rows);
    await file.writeAsString(csvString);
    await box.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$boxName exported and cleared.')));

    if (boxName == 'game_summary') {
      setState(() {
        summaries =
            Hive.box(
              'game_summary',
            ).values.toList().reversed.cast<Map>().toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryBox = Hive.box('game_summary');
    final historyBox = Hive.box('game_history');

    List<FlSpot> spots = [];
    for (int i = 0; i < summaries.length; i++) {
      final avg = double.tryParse(summaries[i]['avgReactionTime'].toString());
      if (avg != null) spots.add(FlSpot(i.toDouble(), avg));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Progress Overview"),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart),
            tooltip: "Session Analysis",
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GameAnalysisScreen()),
                ),
          ),
          IconButton(
            icon: Icon(Icons.download),
            tooltip: "Export & Clear Summary",
            onPressed: () => _exportAndClear(summaryBox, 'game_summary'),
          ),
          IconButton(
            icon: Icon(Icons.delete_sweep),
            tooltip: "Export & Clear History",
            onPressed: () => _exportAndClear(historyBox, 'game_history'),
          ),
        ],
      ),
      body:
          summaries.isEmpty
              ? Center(child: Text("No sessions yet."))
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    "Average Reaction Time",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: pastelBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(blurRadius: 6, color: Colors.black12),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: pastelAccent,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "Session Summaries",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  ...summaries.map(
                    (game) => Card(
                      color: pastelBackground,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Icon(Icons.event, color: pastelAccent),
                        title: Text(
                          "Date: ${game['timestamp'].toString().split('T')[0]}",
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Removed: ${game['blocksRemoved']} blocks"),
                            Text("Avg Reaction: ${game['avgReactionTime']} ms"),
                            Text(
                              "Top Finger: ${game['bestFinger']} (${game['bestFingerAvg']} ms)",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
