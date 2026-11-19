import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Stray animals positioned precisely on the real Sri Lanka Map coordinates
  final _strayPets = [
    {
      'name': 'Max',
      'breed': 'Golden Retriever Mix',
      'location': 'Homagama / NSBM Area',
      'imageUrl': 'https://images.unsplash.com/photo-1543466835-00a7907e9de1',
      'status': 'Stray - Needs Food',
      'top': 580.0,
      'left': 320.0,
    },
    {
      'name': 'Luna',
      'breed': 'Tabby Cat',
      'location': 'Padeniya / Kurunegala Road',
      'imageUrl':
          'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba',
      'status': 'Injured Paw',
      'top': 380.0,
      'left': 280.0,
    },
    {
      'name': 'Rocky',
      'breed': 'Street Puppy',
      'location': 'Kurunegala Town',
      'imageUrl':
          'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e',
      'status': 'Looking for Foster',
      'top': 310.0,
      'left': 340.0,
    },
    {
      'name': 'Simba',
      'breed': 'Local Stray Cat',
      'location': 'Kandy City',
      'imageUrl': 'https://images.unsplash.com/photo-1533738363-b7f9aef128ce',
      'status': 'Hungry & Friendly',
      'top': 440.0,
      'left': 480.0,
    },
    {
      'name': 'Bella',
      'breed': 'Mixed Breed Dog',
      'location': 'Galle Fort',
      'imageUrl':
          'https://images.unsplash.com/photo-1537151608828-ea2b11777ee8',
      'status': 'Needs Medical Care',
      'top': 820.0,
      'left': 250.0,
    },
    {
      'name': 'Charlie',
      'breed': 'Puppy Trio',
      'location': 'Colombo 07',
      'imageUrl': 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b',
      'status': 'Shelter Needed',
      'top': 620.0,
      'left': 240.0,
    },
  ];

  Map? _selectedPet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF5),
      body: Stack(
        children: [
          // 1. Interactive Real Map Viewer (Zoom in, Zoom out, Pan anywhere)
          InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(300),
            minScale: 0.5,
            maxScale: 5.0,
            child: SizedBox(
              width: 1000,
              height: 1200,
              child: Stack(
                children: [
                  // Real Sri Lanka Administrative Map Image
                  Positioned.fill(
                    child: Image.network(
                      'https://www.nationsonline.org/maps/srilanka-administrative-map.jpg',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.white,
                        child: const Center(
                          child: Text(
                            'Map image loading... Please check internet connection.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Stray Animal Markers placed over the real map
                  for (var pet in _strayPets)
                    Positioned(
                      top: (pet['top'] as num).toDouble(),
                      left: (pet['left'] as num).toDouble(),
                      child:
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPet = pet;
                              });
                            },
                            child: Column(
                              children: [
                                // Glowing Photo Circle Marker
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFBF5700,
                                    ), // Pawly Orange accent
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundImage: NetworkImage(
                                      pet['imageUrl'] as String,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    pet['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF251605),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().scale(
                            duration: 400.ms,
                            curve: Curves.easeOutBack,
                          ),
                    ),
                ],
              ),
            ),
          ),

          // 2. Top Header Title bar
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Zoom & Pan freely across the map!'),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFFBF5700),
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom Popup Card when a Marker is Tapped
          if (_selectedPet != null)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child:
                  Container(
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
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            _selectedPet!['imageUrl'] as String,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _selectedPet!['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF251605),
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedPet = null),
                                    child: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedPet!['breed'] as String,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8A7A66),
                                ),
                              ),
                              const SizedBox(height: 4),
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
                                      _selectedPet!['location'] as String,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8A7A66),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
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
                  ),
            ),
        ],
      ),
    );
  }
}
