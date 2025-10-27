import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// Provide your OpenWeatherMap API key at runtime with --dart-define=WEATHER_API_KEY=YOUR_KEY
const String weatherApiKey = String.fromEnvironment('WEATHER_API_KEY', defaultValue: '');

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WeatherHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WeatherData {
  final String city;
  final double temperature; // Celsius
  final String description;
  final String icon;

  WeatherData({required this.city, required this.temperature, required this.description, required this.icon});

  factory WeatherData.fromJson(Map<String, dynamic> j) {
    final city = j['name'] ?? 'Unknown';
    final main = j['main'] ?? {};
    final weatherList = (j['weather'] as List<dynamic>?) ?? [];
    final weather = weatherList.isNotEmpty ? weatherList.first : {};
    final temp = (main['temp'] is num) ? (main['temp'] as num).toDouble() : 0.0;
    final desc = weather['description'] ?? '';
    final icon = weather['icon'] ?? '';
    return WeatherData(city: city, temperature: temp, description: desc, icon: icon);
  }
}

class WeatherService {
  static const _base = 'https://api.openweathermap.org/data/2.5/weather';

  static Future<WeatherData> fetchByLocation(double lat, double lon, {String units = 'metric'}) async {
    final key = weatherApiKey;
    if (key.isEmpty) throw Exception('Missing WEATHER_API_KEY. Run with --dart-define=WEATHER_API_KEY=YOUR_KEY');

    final uri = Uri.parse('$_base?lat=$lat&lon=$lon&units=$units&appid=$key');
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      String msg = 'Failed to fetch weather: ${res.statusCode}';
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['message'] != null) msg = '${body['message']} (code ${res.statusCode})';
      } catch (_) {}
      throw Exception(msg);
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return WeatherData.fromJson(map);
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  late Future<WeatherData> _futureWeather;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _futureWeather = _determineAndFetch();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them in settings.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please open app settings.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
  }

  Future<WeatherData> _determineAndFetch() async {
    setState(() => _statusMessage = 'Acquiring location...');
    final pos = await _determinePosition();
    setState(() => _statusMessage = 'Fetching weather...');
    final weather = await WeatherService.fetchByLocation(pos.latitude, pos.longitude);
    return weather;
  }

  void _refresh() {
    setState(() {
      _futureWeather = _determineAndFetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = weatherApiKey.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
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
                'WEATHER_API_KEY not provided. Run with --dart-define=WEATHER_API_KEY=YOUR_KEY to fetch live weather.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: FutureBuilder<WeatherData>(
              future: _futureWeather,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(), const SizedBox(height: 12), Text(_statusMessage)]));
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
                          Text('Error: ${snapshot.error}'),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                        ],
                      ),
                    ),
                  );
                }

                final w = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(w.city, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (w.icon.isNotEmpty)
                        Image.network('https://openweathermap.org/img/wn/${w.icon}@2x.png', width: 100, height: 100),
                      const SizedBox(height: 6),
                      Text('${w.temperature.toStringAsFixed(1)} °C', style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 8),
                      Text(w.description, style: const TextStyle(fontSize: 18, color: Colors.black54)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
