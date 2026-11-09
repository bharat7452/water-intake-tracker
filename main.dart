import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------
// HydroTrack - Water Intake Tracker
// SDG 6 (Clean Water & Sanitation) | SDG 3 (Good Health & Well-being)
// State management: Provider (ChangeNotifier) | Storage: in-memory (DartPad version)
// ---------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tracker = WaterTracker();
  await tracker.load();
  runApp(ChangeNotifierProvider.value(value: tracker, child: const HydroApp()));
}

// ----------------------------- MODEL / STATE -----------------------------
class WaterTracker extends ChangeNotifier {
  int goal = 2500; // ml per day
  final Map<String, int> history = {}; // 'yyyy-MM-dd' -> ml

  String keyOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int get todayMl => history[keyOf(DateTime.now())] ?? 0;
  double get progress => (todayMl / goal).clamp(0.0, 1.0);
  int get glasses => (todayMl / 250).floor();

  Future<void> load() async {
    // Demo data so the History tab looks populated in DartPad
    final now = DateTime.now();
    const demo = [1800, 2600, 2200, 3000, 1500, 2700];
    for (var i = 0; i < demo.length; i++) {
      history[keyOf(now.subtract(Duration(days: demo.length - i)))] = demo[i];
    }
  }

  void _save() {} // no persistence in DartPad

  void add(int ml) {
    final k = keyOf(DateTime.now());
    history[k] = ((history[k] ?? 0) + ml).clamp(0, 10000);
    _save();
    notifyListeners();
  }

  void resetToday() {
    history.remove(keyOf(DateTime.now()));
    _save();
    notifyListeners();
  }

  void setGoal(int ml) {
    goal = ml;
    _save();
    notifyListeners();
  }

  /// Last 7 days (oldest first) as (date, ml)
  List<MapEntry<DateTime, int>> last7() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return MapEntry(d, history[keyOf(d)] ?? 0);
    });
  }

  /// Consecutive days the goal was met (today counts only if met)
  int get streak {
    int s = 0;
    var d = DateTime.now();
    if ((history[keyOf(d)] ?? 0) < goal) d = d.subtract(const Duration(days: 1));
    while ((history[keyOf(d)] ?? 0) >= goal) {
      s++;
      d = d.subtract(const Duration(days: 1));
    }
    return s;
  }
}

// ----------------------------- APP + THEME -----------------------------
class HydroApp extends StatelessWidget {
  const HydroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HydroTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0288D1)),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFFE1F5FE),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomePage(),
        '/settings': (_) => const SettingsPage(),
      },
    );
  }
}

// ----------------------------- HOME (bottom nav) -----------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  final _pages = const [TodayTab(), HistoryTab(), ImpactTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HydroTrack'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(key: ValueKey(_tab), child: _pages[_tab]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.water_drop), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'History'),
          NavigationDestination(icon: Icon(Icons.public), label: 'SDG Impact'),
        ],
      ),
    );
  }
}

// ----------------------------- TODAY TAB -----------------------------
class TodayTab extends StatelessWidget {
  const TodayTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<WaterTracker>();
    final wide = MediaQuery.of(context).size.width > 600; // responsive
    final ring = _ProgressRing(tracker: t);
    final controls = _Controls(tracker: t);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: wide
          ? Row(children: [Expanded(child: ring), Expanded(child: controls)])
          : Column(children: [ring, const SizedBox(height: 16), controls]),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final WaterTracker tracker;
  const _ProgressRing({required this.tracker});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: tracker.progress),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, value, __) => SizedBox(
            width: 230,
            height: 230,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 230,
                  height: 230,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 18,
                    backgroundColor: cs.primary.withAlpha(38),
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.water_drop, color: cs.primary, size: 36),
                  Text('${tracker.todayMl} ml',
                      style: const TextStyle(
                          fontSize: 34, fontWeight: FontWeight.bold)),
                  Text('of ${tracker.goal} ml',
                      style: TextStyle(color: Colors.grey.shade700)),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          tracker.progress >= 1
              ? 'Goal reached! Great job staying hydrated.'
              : '${tracker.goal - tracker.todayMl} ml to go  |  ${tracker.glasses} glasses',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Chip(
          avatar: const Icon(Icons.local_fire_department, color: Colors.orange),
          label: Text('${tracker.streak}-day streak'),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  final WaterTracker tracker;
  const _Controls({required this.tracker});

  Future<void> _customDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add custom amount'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
                labelText: 'Amount (ml)', border: OutlineInputBorder()),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null) return 'Enter a valid number';
              if (n <= 0 || n > 2000) return 'Enter between 1 and 2000 ml';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                tracker.add(int.parse(ctrl.text));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick add',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final ml in [150, 250, 500])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _QuickButton(
                    ml: ml,
                    onTap: () => tracker.add(ml),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _customDialog(context),
            icon: const Icon(Icons.edit),
            label: const Text('Custom amount'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => tracker.add(-250),
            icon: const Icon(Icons.undo),
            label: const Text('Undo last glass (-250 ml)'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: tracker.resetToday,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset today'),
          ),
        ),
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  final int ml;
  final VoidCallback onTap;
  const _QuickButton({required this.ml, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(children: [
            Icon(ml >= 500 ? Icons.sports_bar : Icons.local_drink,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text('+$ml ml', style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

// ----------------------------- HISTORY TAB -----------------------------
class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<WaterTracker>();
    final data = t.last7();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxMl = [t.goal, ...data.map((e) => e.value)].reduce((a, b) => a > b ? a : b);
    final avg = data.fold<int>(0, (s, e) => s + e.value) ~/ 7;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Last 7 days',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final e in data)
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${e.value}', style: const TextStyle(fontSize: 10)),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      width: 28,
                      height: 140 * (e.value / maxMl),
                      decoration: BoxDecoration(
                        color: e.value >= t.goal
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(days[e.key.weekday - 1],
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 12, height: 12, color: Colors.green),
          const Text('  Goal met     '),
          Container(
              width: 12,
              height: 12,
              color: Theme.of(context).colorScheme.primary),
          const Text('  Below goal'),
        ]),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.insights),
            title: Text('Daily average: $avg ml'),
            subtitle: Text(
                'Days goal met: ${data.where((e) => e.value >= t.goal).length}/7'),
          ),
        ),
      ],
    );
  }
}

// ----------------------------- SDG IMPACT TAB -----------------------------
class ImpactTab extends StatelessWidget {
  const ImpactTab({super.key});

  Widget _card(IconData icon, String title, String body, Color color) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
                backgroundColor: color,
                child: Icon(icon, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(body),
              ]),
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = context.watch<WaterTracker>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(Icons.water_drop, 'SDG 6: Clean Water & Sanitation',
            'Builds awareness of water as a precious resource. Every glass you log is a reminder that safe drinking water is not available to everyone.',
            const Color(0xFF26BDE2)),
        const SizedBox(height: 12),
        _card(Icons.favorite, 'SDG 3: Good Health & Well-being',
            'Proper hydration supports digestion, concentration, kidney function and energy. Tracking builds a healthy daily habit.',
            const Color(0xFF4C9F38)),
        const SizedBox(height: 12),
        _card(Icons.lightbulb, 'Did you know?',
            'Skipping bottled water for safe tap or filtered water also cuts plastic waste. You have logged ${t.todayMl} ml today.',
            Colors.orange),
      ],
    );
  }
}

// ----------------------------- SETTINGS (named route) -----------------------------
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<WaterTracker>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Daily goal: ${t.goal} ml',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          Slider(
            value: t.goal.toDouble(),
            min: 1000,
            max: 5000,
            divisions: 40,
            label: '${t.goal} ml',
            onChanged: (v) => t.setGoal(v.round()),
          ),
          const Text(
              'Tip: a common guideline is about 2 to 3 litres per day, depending on age, weather and activity.'),
        ]),
      ),
    );
  }
}
