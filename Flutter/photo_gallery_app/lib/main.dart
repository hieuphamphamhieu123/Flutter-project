import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const PhotoGalleryApp());
}

class PhotoGalleryApp extends StatelessWidget {
  const PhotoGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Gallery',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const GalleryPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];
  Directory? _storageDir;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initStorageAndLoad();
  }

  Future<void> _initStorageAndLoad() async {
    setState(() => _loading = true);
    final dir = await getApplicationDocumentsDirectory();
    _storageDir = Directory('${dir.path}/photos');
    if (!await _storageDir!.exists()) await _storageDir!.create(recursive: true);
    await _loadImages();
    setState(() => _loading = false);
  }

  Future<void> _loadImages() async {
    if (_storageDir == null) return;
    final files = _storageDir!.listSync().whereType<File>().toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    setState(() {
      _images = files;
    });
  }

  Future<bool> _requestPermission(ImageSource source) async {
    if (kIsWeb) return true; // Web handles permissions differently via browser

    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      return status.isGranted;
    } else {
      // For selecting from gallery, request photos (iOS) or storage (Android)
      if (Platform.isIOS) {
        final status = await Permission.photos.request();
        return status.isGranted;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
  }

  Future<void> _pickAndSave(ImageSource source) async {
    final allowed = await _requestPermission(source);
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied')));
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      if (_storageDir == null) await _initStorageAndLoad();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = picked.path.split('.').last;
      final newPath = '${_storageDir!.path}/photo_\$timestamp.\$ext';
      final saved = await File(picked.path).copy(newPath);
      setState(() => _images.insert(0, saved));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo saved')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving photo: $e')));
    }
  }

  Future<void> _deleteImage(File f) async {
    try {
      await f.delete();
      setState(() => _images.remove(f));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting photo: $e')));
    }
  }

  void _showPickOptions() {
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Take Photo'), onTap: () { Navigator.of(context).pop(); _pickAndSave(ImageSource.camera); }),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Pick from Gallery'), onTap: () { Navigator.of(context).pop(); _pickAndSave(ImageSource.gallery); }),
            ListTile(leading: const Icon(Icons.close), title: const Text('Cancel'), onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Gallery')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _images.isEmpty
              ? const Center(child: Text('No photos yet. Tap + to add.'))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      final f = _images[index];
                      return GestureDetector(
                        onLongPress: () => showDialog<void>(
                          context: context,
                          builder: (d) => AlertDialog(
                            title: const Text('Delete photo?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(d).pop(), child: const Text('Cancel')),
                              ElevatedButton(onPressed: () { Navigator.of(d).pop(); _deleteImage(f); }, child: const Text('Delete')),
                            ],
                          ),
                        ),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FullscreenPhoto(path: f.path))),
                        child: Hero(
                          tag: f.path,
                          child: Image.file(f, fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPickOptions,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

class FullscreenPhoto extends StatelessWidget {
  final String path;
  const FullscreenPhoto({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Hero(tag: path, child: Image.file(File(path))),
      ),
    );
  }
}
