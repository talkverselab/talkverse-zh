import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class HskScreen extends StatefulWidget {
  const HskScreen({super.key});

  @override
  State<HskScreen> createState() => _HskScreenState();
}

class _HskScreenState extends State<HskScreen> {
  final List<_Level> _levels = const [
    _Level('HSK 한자 1급', 'assets/data/hsk/HSK_hanzi_1.txt', Color(0xFF4CAF50)),
    _Level('HSK 한자 2급', 'assets/data/hsk/HSK_hanzi_2.txt', Color(0xFF8BC34A)),
    _Level('HSK 한자 3급', 'assets/data/hsk/HSK_hanzi_3.txt', Color(0xFFCDDC39)),
    _Level('HSK 1급 단어', 'assets/data/hsk/HSK_1.txt', Color(0xFF66BB6A)),
    _Level('HSK 2급 단어', 'assets/data/hsk/HSK_2.txt', Color(0xFFAED581)),
    _Level('HSK 3급 단어', 'assets/data/hsk/HSK_3.txt', Color(0xFFDCE775)),
  ];

  String? _selectedAsset;
  List<String> _items = [];
  bool _loading = false;

  Future<void> _open(String assetPath) async {
    setState(() {
      _selectedAsset = assetPath;
      _loading = true;
      _items = [];
    });
    final raw = await rootBundle.loadString(assetPath);
    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    setState(() {
      _items = lines;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedAsset == null
            ? 'HSK'
            : _levels.firstWhere((l) => l.asset == _selectedAsset).title),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        leading: _selectedAsset != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _selectedAsset = null;
                  _items = [];
                }),
              )
            : null,
      ),
      body: _selectedAsset == null ? _buildList() : _buildDetail(),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _levels.length,
      itemBuilder: (context, i) {
        final level = _levels[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: level.color.withValues(alpha: 0.2),
              child: Icon(Icons.school, color: level.color),
            ),
            title: Text(level.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(level.asset),
          ),
        );
      },
    );
  }

  Widget _buildDetail() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        return ListTile(
          dense: true,
          leading: SizedBox(
            width: 40,
            child: Text(
              '${i + 1}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          title: Text(_items[i], style: const TextStyle(fontSize: 18)),
        );
      },
    );
  }
}

class _Level {
  final String title;
  final String asset;
  final Color color;
  const _Level(this.title, this.asset, this.color);
}
