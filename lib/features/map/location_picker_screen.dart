import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:latlong2/latlong.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  late final Future<vt.Style> _styleFuture;

  static const LatLng _initialLocation = LatLng(7.8731, 80.7718);

  LatLng? _selectedLocation;

  bool _isSearching = false;

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
    _searchController.dispose();
    _styleFuture.then((style) => style.dispose()).catchError((_) {});
    super.dispose();
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      _showMessage('Please type a location name.');
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final client = HttpClient();

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': '$query, Sri Lanka',
        'format': 'jsonv2',
        'limit': '1',
        'countrycodes': 'lk',
      });

      final request = await client.getUrl(uri);

      request.headers.set(
        HttpHeaders.userAgentHeader,
        'PAWLY/1.0 (Flutter mobile app)',
      );

      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Location search failed.');
      }

      final responseBody = await response.transform(utf8.decoder).join();

      final results = jsonDecode(responseBody) as List;

      if (!mounted) return;

      if (results.isEmpty) {
        _showMessage('Location not found. Try another name.');
        return;
      }

      final result = results.first;

      final latitude = double.parse(result['lat']);
      final longitude = double.parse(result['lon']);

      final location = LatLng(latitude, longitude);

      setState(() {
        _selectedLocation = location;
      });

      _mapController.move(location, 15);

      _showMessage('Location found successfully!');
    } catch (e) {
      if (mounted) {
        _showMessage('Unable to search. Check your internet connection.');
      }
    } finally {
      client.close(force: true);

      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirmLocation() {
    if (_selectedLocation == null) {
      _showMessage('Please search for or select a location first.');
      return;
    }

    Navigator.pop(context, _selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Animal Location',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF7DBA7),
        foregroundColor: const Color(0xFF251605),
      ),
      body: Stack(
        children: [
          // OpenFreeMap
          FutureBuilder<vt.Style>(
            future: _styleFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Unable to load map. Check your internet.'),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFBF5700)),
                );
              }

              final style = snapshot.data!;

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialLocation,
                  initialZoom: 7,
                  minZoom: 5,
                  maxZoom: 19,
                  onTap: (tapPosition, point) {
                    setState(() {
                      _selectedLocation = point;
                    });
                  },
                ),
                children: [
                  vt.VectorTileLayer(
                    theme: style.theme,
                    tileProviders: style.providers,
                    rasterSources: style.rasterSources,
                    sprites: style.sprites,
                    glyphs: style.glyphs,
                  ),

                  // Selected location marker
                  if (_selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation!,
                          width: 50,
                          height: 60,
                          child: const Icon(
                            Icons.location_pin,
                            size: 50,
                            color: Color(0xFFBF5700),
                          ),
                        ),
                      ],
                    ),

                  // Map attribution
                  if (style.attributions.isNotEmpty)
                    SimpleAttributionWidget(
                      source: Text(
                        style.attributions.map((a) => a.text).join(' · '),
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                ],
              );
            },
          ),

          // Location search field and SEARCH button
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFFBF5700)),

                  const SizedBox(width: 8),

                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) {
                        _searchLocation();
                      },
                      decoration: const InputDecoration(
                        hintText: 'Type a location (e.g. Kurunegala)',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  ElevatedButton(
                    onPressed: _isSearching ? null : _searchLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBF5700),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'SEARCH',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Confirm location button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _selectedLocation == null ? null : _confirmLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBF5700),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Confirm Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
