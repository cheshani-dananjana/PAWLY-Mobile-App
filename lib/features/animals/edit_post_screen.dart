
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/cloudinary_upload_service.dart';

class EditPostScreen extends StatefulWidget {
  const EditPostScreen({
    super.key,
    required this.postId,
  });

  final String postId;

  @override
  State<EditPostScreen> createState() =>
      _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _orange = Color(0xFFBF5700);
  static const Color _dark = Color(0xFF251605);

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _picker = ImagePicker();

  late final Future<DocumentSnapshot<Map<String, dynamic>>>
      _postFuture;

  bool _initialized = false;
  bool _saving = false;

  String _postType = 'Stray';
  String _previousLocation = '';
  String _previousImageUrl = '';

  File? _replacementPhoto;

  DocumentReference<Map<String, dynamic>> get _postRef =>
      FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId);

  @override
  void initState() {
    super.initState();
    _postFuture = _postRef.get();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeForm(Map<String, dynamic> post) {
    if (_initialized) return;

    _initialized = true;

    _nameController.text =
        (post['animalName'] as String?) ?? '';

    _previousLocation =
        (post['location'] as String?) ?? '';

    _locationController.text = _previousLocation;

    _descriptionController.text =
        (post['description'] as String?) ?? '';

    _previousImageUrl =
        (post['imageUrl'] as String?) ?? '';

    final currentType =
        (post['postType'] as String?) ?? 'Stray';

    _postType = [
      'Stray',
      'Lost',
      'Adoption',
    ].contains(currentType)
        ? currentType
        : 'Stray';
  }

  Future<void> _choosePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
              ),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(
                sheetContext,
                ImageSource.gallery,
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
              ),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(
                sheetContext,
                ImageSource.camera,
              ),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final selected = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (selected != null && mounted) {
        setState(() {
          _replacementPhoto = File(selected.path);
        });
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Could not select photo: $error');
      }
    }
  }

  // Look up updated coordinates if the location changes.
  Future<Map<String, double>?> _coordinatesFor(
    String location,
  ) async {
    final client = HttpClient();

    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': '$location, Sri Lanka',
          'format': 'jsonv2',
          'limit': '1',
          'countrycodes': 'lk',
        },
      );

      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 20));

      request.headers.set(
        HttpHeaders.userAgentHeader,
        'PAWLY/1.0 (Flutter mobile app)',
      );

      final response = await request
          .close()
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
          'Location service is unavailable.',
        );
      }

      final responseText = await utf8.decoder
          .bind(response)
          .join()
          .timeout(const Duration(seconds: 20));

      final results = jsonDecode(responseText);

      if (results is! List || results.isEmpty) {
        return null;
      }

      final first = results.first;

      if (first is! Map) return null;

      final lat =
          double.tryParse(first['lat'].toString());

      final lon =
          double.tryParse(first['lon'].toString());

      if (lat == null || lon == null) {
        return null;
      }

      return {
        'latitude': lat,
        'longitude': lon,
      };
    } finally {
      client.close(force: true);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _savePost() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please log in to edit your post.');
      return;
    }

    setState(() => _saving = true);

    try {
      // Confirm that the current user owns this post.
      final latest = await _postRef.get();
      final post = latest.data();

      if (post == null) {
        throw Exception('The post no longer exists.');
      }

      if (post['userId'] != user.uid) {
        throw Exception(
          'You can edit only your own posts.',
        );
      }

      final updatedLocation =
          _locationController.text.trim();

      final updates = <String, dynamic>{
        'animalName': _nameController.text.trim(),
        'postType': _postType,
        'location': updatedLocation,
        'description':
            _descriptionController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Preserve map coordinates unless location changed.
      if (updatedLocation != _previousLocation) {
        final coords =
            await _coordinatesFor(updatedLocation);

        if (coords == null) {
          throw Exception(
            'Location not found. Try a more '
            'specific Sri Lankan place.',
          );
        }

        updates.addAll(coords);
      }

      // Upload a new photo only if the user selected one.
      if (_replacementPhoto != null) {
        updates['imageUrl'] =
            await CloudinaryUploadService
                .uploadAnimalImage(_replacementPhoto!);
      }

      await _postRef.update(updates);

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to save changes: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text(
          'Edit Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _cream,
        foregroundColor: _dark,
      ),
      body: FutureBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load post: ${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: _orange,
              ),
            );
          }

          final post = snapshot.data!.data();

          if (post == null) {
            return const Center(
              child: Text('This post has been deleted.'),
            );
          }

          if (uid == null || post['userId'] != uid) {
            return const Center(
              child: Text('You cannot edit this post.'),
            );
          }

          _initializeForm(post);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(18),
                  child: SizedBox(
                    height: 200,
                    child: _replacementPhoto != null
                        ? Image.file(
                            _replacementPhoto!,
                            fit: BoxFit.cover,
                          )
                        : _previousImageUrl.isNotEmpty
                            ? Image.network(
                                _previousImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, error, stack) =>
                                        const Icon(
                                  Icons.pets,
                                  color: _orange,
                                  size: 65,
                                ),
                              )
                            : const Icon(
                                Icons.pets,
                                color: _orange,
                                size: 65,
                              ),
                  ),
                ),

                const SizedBox(height: 8),

                TextButton.icon(
                  onPressed:
                      _saving ? null : _choosePhoto,
                  icon: const Icon(
                    Icons.add_a_photo_outlined,
                  ),
                  label: const Text(
                    'Change photo (optional)',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: _orange,
                  ),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _nameController,
                  enabled: !_saving,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Animal name',
                    filled: true,
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter an animal name (or Unknown)'
                          : null,
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: _postType,
                  decoration: const InputDecoration(
                    labelText: 'Post type',
                    filled: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Stray',
                      child: Text('Stray'),
                    ),
                    DropdownMenuItem(
                      value: 'Lost',
                      child: Text('Lost'),
                    ),
                    DropdownMenuItem(
                      value: 'Adoption',
                      child: Text('Adoption'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _postType = value;
                            });
                          }
                        },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _locationController,
                  enabled: !_saving,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    helperText:
                        'Changing location also updates the map marker',
                    filled: true,
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter a location'
                          : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _descriptionController,
                  enabled: !_saving,
                  maxLength: 1000,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    filled: true,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed:
                        _saving ? null : _savePost,
                    icon: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.save_outlined,
                          ),
                    label: Text(
                      _saving
                          ? 'Saving...'
                          : 'Save Changes',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
