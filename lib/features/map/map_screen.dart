import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  late final Future<vt.Style> _styleFuture;

  Map<String, dynamic>? _selectedPet;
  LatLng? _userLocation;
  bool _isLocating = false;

  static const LatLng _sriLankaCenter = LatLng(7.8731, 80.7718);

  @override
  void initState() {
    super.initState();

    _styleFuture = vt.StyleReader(
      uri: 'https://tiles.openfreemap.org/styles/liberty',
    ).read();
  }

  @override
  void dispose() {
    _mapController.dispose();
    unawaited(_styleFuture.then((style) => style.dispose()).catchError((_) {}));
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    if (_isLocating) return;

    setState(() {
      _isLocating = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage('Please turn on your device location.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage('Location permission was denied.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is permanently denied. '
          'Please enable it in your device settings.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      final location = LatLng(position.latitude, position.longitude);

      setState(() {
        _userLocation = location;
        _selectedPet = null;
      });

      _mapController.move(location, 14);
    } catch (e) {
      _showMessage('Unable to get your location. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ANIMAL MARKER
  Widget _buildAnimalMarker(Map<String, dynamic> pet) {
    final imageUrl = pet['imageUrl']?.toString() ?? '';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        debugPrint('DOG TAPPED: ${pet['name']}');

        setState(() {
          _selectedPet = Map<String, dynamic>.from(pet);
        });

        _showMessage('Selected: ${pet['name'] ?? 'Animal'}');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFBF5700),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.orange.shade100,
              backgroundImage: imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : null,
              child: imageUrl.isEmpty
                  ? const Icon(Icons.pets, color: Colors.brown)
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
            child: Text(
              pet['name']?.toString() ?? 'Animal',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF251605),
              ),
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  // SELECTED ANIMAL DETAILS CARD
  Widget _buildSelectedPetCard() {
    if (_selectedPet == null) {
      return const SizedBox.shrink();
    }

    final pet = _selectedPet!;
    final imageUrl = pet['imageUrl']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.orange.shade100,
                        child: const Icon(Icons.pets),
                      );
                    },
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.orange.shade100,
                    child: const Icon(Icons.pets),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pet['name']?.toString() ?? 'Unknown Animal',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF251605),
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _selectedPet = null;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 20, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  pet['breed']?.toString() ?? 'Animal Report',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A7A66),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Color(0xFFBF5700),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pet['location']?.toString() ?? 'Location not specified',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A7A66),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  pet['status']?.toString() ?? 'Animal Report',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFBF5700),
                  ),
                ),
                if ((pet['description']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    pet['description'].toString(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A7A66),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(
      begin: 0.5,
      end: 0,
      duration: 300.ms,
      curve: Curves.easeOutBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF5),
      body: Stack(
        children: [
          // MAP AND FIRESTORE DATA
          FutureBuilder<vt.Style>(
            future: _styleFuture,
            builder: (context, styleSnapshot) {
              if (styleSnapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFBF5700)),
                );
              }

              if (styleSnapshot.hasError || !styleSnapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Unable to load the map. '
                      'Please check your internet connection.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final style = styleSnapshot.data!;

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .snapshots(),
                builder: (context, postsSnapshot) {
                  if (postsSnapshot.hasError) {
                    debugPrint('FIRESTORE ERROR: ${postsSnapshot.error}');

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Unable to load animal posts:\n'
                          '${postsSnapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (postsSnapshot.connectionState ==
                          ConnectionState.waiting &&
                      !postsSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFBF5700),
                      ),
                    );
                  }

                  final List<Map<String, dynamic>> pets = [];

                  if (postsSnapshot.hasData) {
                    debugPrint(
                      'TOTAL FIRESTORE POSTS: '
                      '${postsSnapshot.data!.docs.length}',
                    );

                    for (final doc in postsSnapshot.data!.docs) {
                      final data = doc.data();

                      debugPrint(
                        'POST: ${data['animalName']} | '
                        'Latitude: ${data['latitude']} | '
                        'Longitude: ${data['longitude']}',
                      );

                      final latitude = data['latitude'];
                      final longitude = data['longitude'];

                      if (latitude is! num || longitude is! num) {
                        debugPrint(
                          'SKIPPED POST: '
                          '${data['animalName']} '
                          '(Missing or invalid coordinates)',
                        );
                        continue;
                      }

                      pets.add({
                        'name': data['animalName'] ?? 'Unknown Animal',
                        'breed': data['postType'] ?? 'Animal Report',
                        'location':
                            data['location'] ?? 'Location not specified',
                        'imageUrl': data['imageUrl'] ?? '',
                        'status': data['postType'] ?? 'Animal Report',
                        'description': data['description'] ?? '',
                        'latitude': latitude.toDouble(),
                        'longitude': longitude.toDouble(),
                      });
                    }

                    debugPrint('ANIMAL MARKERS: ${pets.length}');
                  }

                  return Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: _sriLankaCenter,
                          initialZoom: 7,
                          minZoom: 5,
                          maxZoom: 19,
                        ),
                        children: [
                          vt.VectorTileLayer(
                            theme: style.theme,
                            tileProviders: style.providers,
                            rasterSources: style.rasterSources,
                            sprites: style.sprites,
                            glyphs: style.glyphs,
                          ),
                          MarkerLayer(
                            markers: [
                              for (final pet in pets)
                                Marker(
                                  point: LatLng(
                                    pet['latitude'] as double,
                                    pet['longitude'] as double,
                                  ),
                                  width: 75,
                                  height: 85,
                                  child: _buildAnimalMarker(pet),
                                ),
                              if (_userLocation != null)
                                Marker(
                                  point: _userLocation!,
                                  width: 45,
                                  height: 45,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.my_location,
                                        color: Colors.blue,
                                        size: 25,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (style.attributions.isNotEmpty)
                            SimpleAttributionWidget(
                              source: Text(
                                style.attributions
                                    .map((a) => a.text)
                                    .join(' · '),
                                style: const TextStyle(fontSize: 9),
                              ),
                            ),
                        ],
                      ),

                      // ANIMAL MARKER COUNTER
                      Positioned(
                        bottom: 20,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 6),
                            ],
                          ),
                          child: Text(
                            'Animal markers: ${pets.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF251605),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          // TOP BAR AND MY LOCATION BUTTON
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.map_rounded,
                        color: Color(0xFFBF5700),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sri Lanka Stray Radar',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF251605),
                        ),
                      ),
                    ],
                  ),
                ),
                FloatingActionButton.small(
                  backgroundColor: Colors.white,
                  elevation: 3,
                  onPressed: _goToMyLocation,
                  child: _isLocating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFBF5700),
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          color: Color(0xFFBF5700),
                        ),
                ),
              ],
            ),
          ),

          // SELECTED DOG DETAILS
          if (_selectedPet != null)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _buildSelectedPetCard(),
            ),
        ],
      ),
    );
  }
}
