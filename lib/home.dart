import 'package:flutter/material.dart';
import 'auth.dart';
import 'auth_screens.dart';
import 'db.dart';
import 'edit.dart';
import 'main.dart';
import 'sections.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  int _i = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _i, children: [
          for (final s in sections) SectionPage(s),
          const SearchPage(),
          const ProfilePage(),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: (v) => setState(() => _i = v),
          destinations: [
            for (final s in sections) NavigationDestination(icon: Icon(s.icon), label: s.title),
            const NavigationDestination(icon: Icon(Icons.search), label: 'Пошук'),
            const NavigationDestination(icon: Icon(Icons.person), label: 'Профіль'),
          ],
        ),
      );
}

Widget recordTile(Section s,  r, VoidCallback onTap, [VoidCallback? onDelete]) {
  final sub = s.fields.skip(1).where((f) => f.key != 'date').map((f) => '${r[f.key] ?? ''}').firstWhere((v) => v.isNotEmpty, orElse: () => '');
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: ListTile(
      leading: CircleAvatar(child: Icon(s.icon)),
      title: Text('${r[s.fields.first.key]}'),
      subtitle: Text([toUi(r['date']), sub].where((e) => e.isNotEmpty).join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: onDelete == null ? null : IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
      onTap: onTap,
    ),
  );
}

class SectionPage extends StatefulWidget {
  final Section s;
  const SectionPage(this.s, {super.key});
  @override
  State<SectionPage> createState() => _SectionPageState();
}

class _SectionPageState extends State<SectionPage> {
  List<Rec> _items = [];
  String _q = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await Db.list(widget.s, Auth.userId!, q: _q);
    if (mounted) setState(() => _items = r);
  }

  Future<void> _open(Rec? rec) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => EditScreen(section: widget.s, record: rec)));
    _load();
  }

  Future<void> _delete(Rec r) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text('Видалити запис?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Ні')),
                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Так')),
              ],
            ));
    if (ok == true) {
      await Db.delete(widget.s, r['id'] as int);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.s.title)),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Пошук у розділі', border: OutlineInputBorder()),
                onChanged: (v) {
                  _q = v;
                  _load();
                }),
          ),
          Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('Записів немає'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (_, i) => recordTile(widget.s, _items[i], () => _open(_items[i]), () => _delete(_items[i])))),
        ]),
        floatingActionButton: FloatingActionButton(onPressed: () => _open(null), child: const Icon(Icons.add)),
      );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final Map<Section, List<Rec>> _res = {};

  Future<void> _search(String q) async {
    _res.clear();
    if (q.trim().isNotEmpty) {
      for (final s in sections) {
        final r = await Db.list(s, Auth.userId!, q: q);
        if (r.isNotEmpty) _res[s] = r;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Пошук по всій історії')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Ліки, лікар, діагноз...', border: OutlineInputBorder()),
                onChanged: _search),
          ),
          Expanded(
            child: ListView(children: [
              for (final e in _res.entries) ...[
                Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: Text(e.key.title, style: Theme.of(context).textTheme.titleMedium)),
                for (final r in e.value)
                  recordTile(e.key, r, () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditScreen(section: e.key, record: r)))),
              ]
            ]),
          ),
        ]),
      );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Профіль')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 48)),
          const SizedBox(height: 12),
          Center(child: Text(Auth.name, style: Theme.of(context).textTheme.headlineSmall)),
          Center(child: Text(Auth.email)),
          const SizedBox(height: 24),
          ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Вийти'),
              onTap: () async {
                await Auth.logout();
                if (context.mounted) goTo(context, const LoginScreen());
              }),
          ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Видалити акаунт', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeleteAccountScreen()))),
        ]),
      );
}
