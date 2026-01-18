import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_menu.dart'; // for navigation

const String PET_BOX = 'petBox';
const String STREAK_BOX = 'streakBox';
const String TRANSACTION_BOX = 'transactionBox';
const String CHALLENGE_BOX = 'challengeBox'; //  new Hive box for challenges

class GrowPetScreen extends StatefulWidget {
  const GrowPetScreen({Key? key}) : super(key: key);

  @override
  State<GrowPetScreen> createState() => _GrowPetScreenState();
}

class _GrowPetScreenState extends State<GrowPetScreen>
    with SingleTickerProviderStateMixin {
  Box? _petBox;
  Box? _streakBox;
  Box? _txBox;
  Box? _challengeBox;
  bool _boxesReady = false;

  double todayTarget = 100.0;
  double currentSavedToday = 0.0;
  int streak = 0;
  DateTime? lastCheckedDate;

  late AnimationController _pulseController;
  Timer? _midnightTimer;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Set<int> _completedChallenges = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _openBoxesAndLoad();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _midnightTimer?.cancel();
    super.dispose();
  }

  Future<void> _openBoxesAndLoad() async {
    try {
      _petBox = Hive.isBoxOpen(PET_BOX)
          ? Hive.box(PET_BOX)
          : await Hive.openBox(PET_BOX);
      _streakBox = Hive.isBoxOpen(STREAK_BOX)
          ? Hive.box(STREAK_BOX)
          : await Hive.openBox(STREAK_BOX);
      _txBox = Hive.isBoxOpen(TRANSACTION_BOX)
          ? Hive.box(TRANSACTION_BOX)
          : await Hive.openBox(TRANSACTION_BOX);
      _challengeBox = Hive.isBoxOpen(CHALLENGE_BOX)
          ? Hive.box(CHALLENGE_BOX)
          : await Hive.openBox(CHALLENGE_BOX);

      //  Load saved challenge completions safely
      final todayKey = _challengeKeyForToday();
      final saved = _challengeBox?.get(todayKey);
      if (saved != null && saved is List) {
        _completedChallenges.addAll(saved.cast<int>());
      }

      setState(() {
        todayTarget = (_petBox!.get('todayTarget') ?? 100.0) as double;
        currentSavedToday = (_petBox!.get(_keyForToday()) ?? 0.0) as double;
        streak = (_streakBox!.get('streak') ?? 0) as int;
        final lastIso = _streakBox!.get('lastChecked');
        lastCheckedDate = lastIso != null ? DateTime.tryParse(lastIso) : null;
        _boxesReady = true;
      });

      await _syncFromFirebaseIfAuthenticated();
      _scheduleMidnightCheck();
    } catch (e) {
      debugPrint('Error opening Hive boxes: $e');
    }
  }

  String _keyForToday() =>
      'saved_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
  String _challengeKeyForToday() =>
      'completed_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';

  Future<void> _setTodayTarget(double newTarget) async {
    setState(() => todayTarget = newTarget);
    if (!_boxesReady) return;
    await _petBox!.put('todayTarget', newTarget);
    _syncToFirebase({'todayTarget': newTarget});
  }

  Future<void> _addSavings(double amount) async {
    if (!_boxesReady || _petBox == null) return;

    currentSavedToday += amount;
    if (currentSavedToday < 0) currentSavedToday = 0;
    await _petBox!.put(_keyForToday(), currentSavedToday);

    if (currentSavedToday >= todayTarget) {
      await _handleGoalAchieved();
    }

    _syncToFirebase({
      'currentSavedToday': currentSavedToday,
      'lastSavedAt': DateTime.now().toIso8601String(),
    });

    setState(() {});
  }

  Future<void> _handleGoalAchieved() async {
    if (!_boxesReady || _streakBox == null || _petBox == null) return;

    final todayIso = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastIso = _streakBox!.get('lastChecked');
    if (lastIso == todayIso) return;

    streak = (_streakBox!.get('streak') ?? 0) as int;
    streak += 1;
    await _streakBox!.put('streak', streak);
    await _streakBox!.put('lastChecked', todayIso);

    final growth = (_petBox!.get('growth') ?? 0) as int;
    await _petBox!.put('growth', growth + 1);

    final tx = {
      'amount': currentSavedToday,
      'date': DateTime.now().toIso8601String(),
      'note': 'Goal achieved - streak bonus',
    };
    await _txBox?.add(tx);

    _syncToFirebase({'streak': streak, 'growth': growth + 1});
    _showCelebration();
    setState(() {});
  }

  void _showCelebration() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Goal achieved!'),
        content: const Text('Your coin pet leveled up 🎉'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yay!'),
          )
        ],
      ),
    );
  }

  Future<void> _syncToFirebase(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('grow_pet')
          .doc('state')
          .set(data, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _syncFromFirebaseIfAuthenticated() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('grow_pet')
          .doc('state')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data.containsKey('todayTarget')) {
          todayTarget = (data['todayTarget'] as num).toDouble();
          if (_boxesReady) await _petBox!.put('todayTarget', todayTarget);
        }
        if (data.containsKey('currentSavedToday')) {
          currentSavedToday = (data['currentSavedToday'] as num).toDouble();
          if (_boxesReady)
            await _petBox!.put(_keyForToday(), currentSavedToday);
        }
        if (data.containsKey('streak')) {
          streak = data['streak'] as int;
          if (_boxesReady) await _streakBox!.put('streak', streak);
        }
        setState(() {});
      }
    } catch (_) {}
  }

  void _scheduleMidnightCheck() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now) + const Duration(seconds: 1);
    _midnightTimer = Timer(diff, () async {
      await _onNewDay();
      _scheduleMidnightCheck();
    });
  }

  Future<void> _onNewDay() async {
  if (!_boxesReady) return;

  //  Reset streak if yesterday’s goal wasn’t met
  final yesterdayKey =
      'saved_${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)))}';
  final yesterdaySaved = (_petBox!.get(yesterdayKey) ?? 0.0) as double;
  final yesterdayTarget =
      (_petBox!.get('todayTarget') ?? todayTarget) as double;
  final lastIso = _streakBox!.get('lastChecked');
  final yesterdayIso = DateFormat('yyyy-MM-dd')
      .format(DateTime.now().subtract(const Duration(days: 1)));

  if (yesterdaySaved < yesterdayTarget && lastIso != yesterdayIso) {
    await _streakBox!.put('streak', 0);
    streak = 0;
    await _streakBox!.put('lastChecked', null);
    _syncToFirebase({'streak': 0, 'lastChecked': null});
  }

  //  Reset challenges daily
  _completedChallenges.clear();
  await _challengeBox?.clear();

  //  Reset savings for the new day
  final todayKey = _keyForToday();
  currentSavedToday = 0.0;
  await _petBox!.put(todayKey, 0.0);

  //  Optionally log reset date for tracking
  final todayIso = DateFormat('yyyy-MM-dd').format(DateTime.now());
  await _petBox!.put('lastResetDate', todayIso);

  //  Sync reset to Firebase so it stays consistent
  _syncToFirebase({
    'currentSavedToday': 0.0,
    'lastResetDate': todayIso,
  });

  setState(() {});
}


  List<Challenge> _generateChallenges() {
    final t = todayTarget;
    return [
      Challenge('Skip one coffee ☕', (t * 0.05).roundToDouble()),
      Challenge('Pack lunch 🍱', (t * 0.1).roundToDouble()),
      Challenge('Avoid impulse buy 🛍️', (t * 0.08).roundToDouble()),
      Challenge('Use public transport 🚌', (t * 0.03).roundToDouble()),
    ];
  }

  // 🪙 Coin pet
  Widget _buildCoinPet() {
    final growth = (_petBox?.get('growth') ?? 0) as int;
    final level = (growth ~/ 3) + 1;
    final progress = (currentSavedToday / todayTarget).clamp(0.0, 1.0);
    final eyeOffset = sin(_pulseController.value * pi) * 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: Tween(begin: 0.98, end: 1.06)
              .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 160 + (level * 6),
                height: 160 + (level * 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.2 + level * 0.02),
                      blurRadius: 30 + level * 2,
                    ),
                  ],
                ),
              ),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.amber, Color(0xFFFFD54F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.orange.shade700, width: 3),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 40,
                      left: 40 + eyeOffset,
                      child: _buildEye(),
                    ),
                    Positioned(
                      top: 40,
                      right: 40 - eyeOffset,
                      child: _buildEye(),
                    ),
                    Positioned(
                      bottom: 25,
                      child: CustomPaint(size: const Size(30, 10), painter: SmilePainter()),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text('Streak: $streak',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${currentSavedToday.toStringAsFixed(0)} / ${todayTarget.toStringAsFixed(0)} saved',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
              onPressed: _showEditTargetDialog,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Lv $level',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)),
      ],
    );
  }

  Widget _buildEye() => Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
      );

  Widget _buildChallengeCard(Challenge ch, int index) {
    final isDone = _completedChallenges.contains(index);
    return Card(
      color: isDone ? Colors.green[50] : null,
      child: ListTile(
        title: Text(ch.title),
        subtitle: Text('+₱${ch.reward.toStringAsFixed(0)}'),
        trailing: isDone
            ? const Icon(Icons.check_circle, color: Colors.green)
            : ElevatedButton(
                onPressed: () async {
                  //  Prevent null crash
                  if (_challengeBox == null || !_boxesReady) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please wait... still loading data')),
                    );
                    return;
                  }

                  await _addSavings(ch.reward);
                  setState(() => _completedChallenges.add(index));

                  await _challengeBox!.put(
                    _challengeKeyForToday(),
                    _completedChallenges.toList(),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Challenge completed: +₱${ch.reward.toStringAsFixed(0)}',
                      ),
                    ),
                  );
                },
                child: const Text('Done'),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_boxesReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final challenges = _generateChallenges();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.home_rounded, color: Colors.blue),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainMenu()),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSaveDialog,
        label: const Text('Add Save'),
        icon: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _buildCoinPet()),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Daily Challenges',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...List.generate(
                      challenges.length,
                      (i) => _buildChallengeCard(challenges[i], i),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddSaveDialog() async {
    final controller = TextEditingController(text: '0');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add saved amount (₱)'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final n = double.tryParse(controller.text);
              if (n != null) {
                await _addSavings(n);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  Future<void> _showEditTargetDialog() async {
    final controller = TextEditingController(text: todayTarget.toStringAsFixed(0));
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit today’s save goal (₱)'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final n = double.tryParse(controller.text);
              if (n != null && n > 0) {
                await _setTodayTarget(n);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }
}

class SmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    canvas.drawArc(rect, 0, pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Challenge {
  final String title;
  final double reward;
  Challenge(this.title, this.reward);
}
