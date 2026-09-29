import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

// شغّل بـ: flutter run --dart-define=GEMINI_KEY=مفتاحك
const _key = String.fromEnvironment('GEMINI_KEY');
const _model = 'gemini-3.8-flash'; // غيّره لو جوجل حدّثت الاسم
const _prompt =
    'أنت مدرس هندسة خبير. حل المسألة خطوة بخطوة بالعربية المبسطة، '
    'واكتب المعادلات بوضوح، وفي الآخر اشرح الفكرة الأساسية في سطرين.';

const _cyan = Color(0xFF00CEC9);
const _violet = Color(0xFF6C5CE7);
const _bg = Color(0xFF0B1030);

final List<String> history = [];

Future<String> solve({Uint8List? img, String? text}) async {
  if (_key.isEmpty) {
    return 'مفيش مفتاح Gemini.\nشغّل التطبيق بالأمر:\nflutter run --dart-define=GEMINI_KEY=مفتاحك';
  }
  try {
    final m = GenerativeModel(model: _model, apiKey: _key);
    final parts = <Part>[
      TextPart(_prompt),
      if (text != null) TextPart(text),
      if (img != null) DataPart('image/jpeg', img),
    ];
    final r = await m.generateContent([Content.multi(parts)]);
    final out = r.text ?? 'مفيش رد، جرّب تاني.';
    history.insert(0, out);
    return out;
  } catch (e) {
    return 'حصل خطأ في الاتصال: $e';
  }
}

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'مهندس',
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: _bg,
          colorScheme: ColorScheme.fromSeed(
              seedColor: _violet, brightness: Brightness.dark),
        ),
        builder: (c, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const Shell(),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  @override
  Widget build(BuildContext context) {
    final tabs = [const Home(), const Hist(), const Sim(), const SettingsTab()];
    return Scaffold(
      body: SafeArea(child: tabs[i]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (v) => setState(() => i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.history), label: 'السجل'),
          NavigationDestination(icon: Icon(Icons.threed_rotation), label: 'المحاكاة'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  Future<void> _snap(BuildContext c) async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 80);
    if (x == null || !c.mounted) return;
    final b = await x.readAsBytes();
    if (!c.mounted) return;
    Navigator.push(
        c, MaterialPageRoute(builder: (_) => ResultPage(solve(img: b))));
  }

  @override
  Widget build(BuildContext c) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('أهلاً بك يا دكتور',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Center(
            child: GestureDetector(
              onTap: () => _snap(c),
              child: Container(
                width: 230,
                height: 230,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_violet, _cyan]),
                  boxShadow: [BoxShadow(color: Color(0x6600CEC9), blurRadius: 40)],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 70),
                    SizedBox(height: 12),
                    Text('صوّر المسألة\nوابدأ الانبهار',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Row(children: [
            Expanded(child: TopicCard(Icons.grid_on, 'المصفوفات')),
            SizedBox(width: 12),
            Expanded(child: TopicCard(Icons.show_chart, 'بحوث العمليات')),
          ]),
        ],
      );
}

class TopicCard extends StatelessWidget {
  final IconData icon;
  final String title;
  const TopicCard(this.icon, this.title, {super.key});
  @override
  Widget build(BuildContext c) => InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
            c, MaterialPageRoute(builder: (_) => TextPage(title))),
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: _cyan),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
}

class TextPage extends StatefulWidget {
  final String title;
  const TextPage(this.title, {super.key});
  @override
  State<TextPage> createState() => _TextPageState();
}

class _TextPageState extends State<TextPage> {
  final t = TextEditingController();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            TextField(
              controller: t,
              maxLines: 6,
              decoration: const InputDecoration(
                  hintText: 'اكتب المسألة هنا', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (t.text.trim().isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ResultPage(
                            solve(text: '${widget.title}: ${t.text}'))),
                  );
                },
                child: const Text('حلّ المسألة'),
              ),
            ),
          ]),
        ),
      );
}

class ResultPage extends StatelessWidget {
  final Future<String> f;
  const ResultPage(this.f, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الحل')),
        body: FutureBuilder<String>(
          future: f,
          builder: (c, s) => s.hasData
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: SelectableText(s.data!,
                      style: const TextStyle(fontSize: 17, height: 1.7)))
              : const Center(child: CircularProgressIndicator()),
        ),
      );
}

class Hist extends StatelessWidget {
  const Hist({super.key});
  @override
  Widget build(BuildContext c) => history.isEmpty
      ? const Center(child: Text('مفيش مسائل لسه. صوّر أول مسألة من الرئيسية.'))
      : ListView.builder(
          itemCount: history.length,
          itemBuilder: (_, k) => ListTile(
            title: Text(history[k], maxLines: 2, overflow: TextOverflow.ellipsis),
            onTap: () => Navigator.push(c,
                MaterialPageRoute(builder: (_) => ResultPage(Future.value(history[k])))),
          ),
        );
}

class Sim extends StatefulWidget {
  const Sim({super.key});
  @override
  State<Sim> createState() => _SimState();
}

class _SimState extends State<Sim> {
  double deg = 30;
  @override
  Widget build(BuildContext context) {
    final r = deg * math.pi / 180;
    final c = math.cos(r), s = math.sin(r);
    String f(double v) => v.toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Text('دوران المصفوفة',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text('[ ${f(c)}  ${f(-s)} ]\n[ ${f(s)}   ${f(c)} ]',
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 22, fontFamily: 'monospace')),
        const SizedBox(height: 16),
        Expanded(child: CustomPaint(size: Size.infinite, painter: _Painter(deg))),
        Text('الزاوية: ${deg.round()}°'),
        Slider(
            value: deg,
            min: 0,
            max: 360,
            onChanged: (v) => setState(() => deg = v)),
      ]),
    );
  }
}

class _Painter extends CustomPainter {
  final double deg;
  _Painter(this.deg);

  Path _square(Offset o, double angle) {
    const k = 70.0;
    final cs = math.cos(angle), sn = math.sin(angle);
    final pts = <List<double>>[[0, 0], [1, 0], [1, 1], [0, 1]];
    final p = Path();
    for (var j = 0; j < 4; j++) {
      final x = pts[j][0] * cs - pts[j][1] * sn;
      final y = pts[j][0] * sn + pts[j][1] * cs;
      final pt = Offset(o.dx + x * k, o.dy - y * k);
      if (j == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    return p;
  }

  @override
  void paint(Canvas cv, Size s) {
    final o = Offset(s.width / 2, s.height / 2);
    final axis = Paint()..color = Colors.white24;
    cv.drawLine(Offset(0, o.dy), Offset(s.width, o.dy), axis);
    cv.drawLine(Offset(o.dx, 0), Offset(o.dx, s.height), axis);
    cv.drawPath(
        _square(o, 0),
        Paint()
          ..color = Colors.white38
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    cv.drawPath(_square(o, deg * math.pi / 180),
        Paint()..color = _cyan.withAlpha(160));
  }

  @override
  bool shouldRepaint(_Painter old) => old.deg != deg;
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'النموذج: $_model\nمفتاح Gemini بيتحط وقت التشغيل بـ --dart-define=GEMINI_KEY',
              textAlign: TextAlign.center),
        ),
      );
}
