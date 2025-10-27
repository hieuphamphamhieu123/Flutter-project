import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// The app reads the NewsAPI key from a dart-define value called NEWSAPI_KEY.
// Run with: flutter run --dart-define=NEWSAPI_KEY=your_api_key

void main() {
  runApp(const NewsReaderApp());
}

final String newsApiKey = const String.fromEnvironment('NEWSAPI_KEY', defaultValue: '');

class NewsReaderApp extends StatelessWidget {
  const NewsReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News Reader',
      theme: ThemeData(primarySwatch: Colors.blueGrey),
      home: const NewsHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Article {
  final String title;
  final String? description;
  final String? urlToImage;
  final String url;
  final String? content;
  final String? sourceName;

  Article({required this.title, required this.url, this.description, this.urlToImage, this.content, this.sourceName});

  factory Article.fromJson(Map<String, dynamic> j) {
    return Article(
      title: j['title'] ?? 'No title',
      description: j['description'],
      urlToImage: j['urlToImage'],
      url: j['url'] ?? '',
      content: j['content'],
      sourceName: (j['source'] != null && j['source']['name'] != null) ? j['source']['name'] : null,
    );
  }
}

class NewsService {
  static const _base = 'https://newsapi.org/v2/top-headlines';

  static Future<List<Article>> fetchTopHeadlines({String country = 'us'}) async {
    final key = newsApiKey;
    if (key.isEmpty) throw Exception('Missing NEWSAPI_KEY. Provide it with --dart-define=NEWSAPI_KEY=YOUR_KEY');

    final uri = Uri.parse('$_base?country=$country&apiKey=$key');
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      String msg = 'Failed to fetch articles: ${res.statusCode}';
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['message'] != null) msg = '${body['message']} (code ${res.statusCode})';
      } catch (_) {}
      throw Exception(msg);
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final items = map['articles'] as List<dynamic>? ?? [];
    return items.map((e) => Article.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class NewsHomePage extends StatefulWidget {
  const NewsHomePage({super.key});

  @override
  State<NewsHomePage> createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  late Future<List<Article>> _futureArticles;
  String _country = 'us';

  @override
  void initState() {
    super.initState();
    _futureArticles = NewsService.fetchTopHeadlines(country: _country);
  }

  void _reload() {
    setState(() {
      _futureArticles = NewsService.fetchTopHeadlines(country: _country);
    });
  }

  void _changeCountry(String? c) {
    if (c == null) return;
    setState(() {
      _country = c;
      _futureArticles = NewsService.fetchTopHeadlines(country: _country);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = newsApiKey.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('News Reader'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _changeCountry,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'us', child: Text('US')),
              PopupMenuItem(value: 'gb', child: Text('UK')),
              PopupMenuItem(value: 'ca', child: Text('Canada')),
              PopupMenuItem(value: 'au', child: Text('Australia')),
            ],
            icon: const Icon(Icons.public),
            tooltip: 'Country',
          ),
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          if (!hasKey)
            Container(
              color: Colors.yellow[700],
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              child: const Text(
                'NEWSAPI_KEY not provided. Run with --dart-define=NEWSAPI_KEY=YOUR_KEY to fetch live articles.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Article>>(
              future: _futureArticles,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Text('Error: ${"${snapshot.error}"}') ,
                          const SizedBox(height: 12),
                          ElevatedButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                        ],
                      ),
                    ),
                  );
                }

                final articles = snapshot.data ?? [];
                if (articles.isEmpty) {
                  return const Center(child: Text('No articles found.'));
                }

                return ListView.separated(
                  itemCount: articles.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final a = articles[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.all(8),
                      leading: a.urlToImage != null
                          ? SizedBox(
                              width: 100,
                              child: Image.network(
                                a.urlToImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                              ),
                            )
                          : const SizedBox(width: 100, child: Icon(Icons.image)),
                      title: Text(a.title),
                      subtitle: Text(a.sourceName ?? ''),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticleDetailPage(article: a))),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ArticleDetailPage extends StatelessWidget {
  final Article article;
  const ArticleDetailPage({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article.sourceName ?? 'Article'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              final uri = Uri.tryParse(article.url);
              if (uri == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid URL')));
                return;
              }
              if (!await launchUrl(uri)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open URL')));
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.urlToImage != null)
                Image.network(article.urlToImage!, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
              const SizedBox(height: 12),
              Text(article.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (article.description != null) Text(article.description!),
              const SizedBox(height: 12),
              if (article.content != null) Text(article.content!),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(article.url);
                  if (uri == null) return;
                  await launchUrl(uri);
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open original article'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
