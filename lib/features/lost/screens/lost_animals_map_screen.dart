import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../services/lost_animal_service.dart';

class LostAnimalsMapScreen extends StatefulWidget {
  const LostAnimalsMapScreen({super.key});

  @override
  State<LostAnimalsMapScreen> createState() => _LostAnimalsMapScreenState();
}

class _LostAnimalsMapScreenState extends State<LostAnimalsMapScreen> {
  late GoogleMapController mapController;
  LatLng _currentPosition = const LatLng(
    7.8731,
    80.7718,
  ); // Default to Sri Lanka
  bool _isLoading = true;
  final Set<Marker> _markers = {};
  final LostAnimalService _service = LostAnimalService();

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _listenToLostAnimals();
  }

  // Fetch real-time lost animals and create map pins
  void _listenToLostAnimals() {
    _service.getLostAnimalsStream().listen((animals) {
      setState(() {
        _markers.clear();
        for (var animal in animals) {
          _markers.add(
            Marker(
              markerId: MarkerId(animal.id),
              position: LatLng(animal.latitude, animal.longitude),
              infoWindow: InfoWindow(
                title: animal.name,
                snippet: animal.description,
              ),
            ),
          );
        }
      });
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });

    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition, 14.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost Animals Near Me'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 14.0,
              ),
              myLocationEnabled: true,
              markers: _markers,
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to "Report Lost Animal" form
          print("Report tapped!");
        },
        label: const Text('Report Lost'),
        icon: const Icon(Icons.add_location_alt),
        backgroundColor: const Color(0xFFBF5700),
      ),
    );
  }
}
