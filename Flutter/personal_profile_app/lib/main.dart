import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme(bool dark) {
    setState(() {
      _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Profile',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
      ),
      home: HomePage(onThemeChanged: _toggleTheme, themeMode: _themeMode),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  final void Function(bool) onThemeChanged;
  final ThemeMode themeMode;

  const HomePage({super.key, required this.onThemeChanged, required this.themeMode});

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget _buildAvatar(BuildContext context) {
    // Try to load a local asset at assets/profile.jpg; if not available, show initials.
    return FutureBuilder<bool>(
      future: _assetExists('assets/profile.jpg'),
      builder: (context, snapshot) {
        final hasAsset = snapshot.data ?? false;
        if (hasAsset) {
          return CircleAvatar(
            radius: 48,
            backgroundImage: const AssetImage('assets/profile.jpg'),
          );
        }
        return const CircleAvatar(
          radius: 48,
          child: Text(
            'JD',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('John Doe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: Text('Flutter Developer • UI/UX Enthusiast'),
            ),
            SizedBox(height: 8),
            Text('About', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text('Passionate developer building clean and responsive mobile apps with Flutter.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsCard(BuildContext context) {
    final skills = ['Flutter', 'Dart', 'Firebase', 'REST', 'UI/UX'];
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Skills', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((s) => Chip(label: Text(s))).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Website'),
            subtitle: const Text('https://your-website.example'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open website'))),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.mail),
            title: const Text('Email'),
            subtitle: const Text('you@example.com'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compose email'))),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('LinkedIn'),
            subtitle: const Text('linkedin.com/in/yourprofile'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open LinkedIn'))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Profile'),
        actions: [
          Row(
            children: [
              const Icon(Icons.light_mode),
              Switch(
                value: themeMode == ThemeMode.dark,
                onChanged: (v) => onThemeChanged(v),
              ),
              const Icon(Icons.dark_mode),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;

          if (isWide) {
            // Two-column layout for wide screens
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: avatar + info
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildAvatar(context),
                        const SizedBox(height: 12),
                        _buildInfoCard(context),
                        _buildContactsCard(context),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Right column: skills and other details
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildSkillsCard(context),
                        // Add more cards here (projects, experience)
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // Mobile / narrow layout
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(context),
                const SizedBox(height: 12),
                _buildInfoCard(context),
                _buildSkillsCard(context),
                _buildContactsCard(context),
              ],
            ),
          );
        },
      ),
    );
  }
}
