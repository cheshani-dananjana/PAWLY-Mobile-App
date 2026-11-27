import '../reporting/report_post_screen.dart';
import '../donations/donations_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../adoption/apply_adoption_screen.dart';
import '../tendering/tender_care_screen.dart';

class AnimalDetailsScreen extends StatelessWidget {
  const AnimalDetailsScreen({
    super.key,
    required this.postId,
  });

  final String postId;

  static const cream = Color(0xFFFDF8ED);
  static const orange = Color(0xFFBF5700);
  static const dark = Color(0xFF251605);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _messageScreen(
            'Could not load animal details.',
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: cream,
            body: const Center(
              child: CircularProgressIndicator(color: orange),
            ),
          );
        }

        final data = snapshot.data!.data();

        if (data == null) {
          return _messageScreen(
            'This animal post is no longer available.',
          );
        }

        String field(String key, String fallback) {
          final value = data[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
          return fallback;
        }

        final name = field('animalName', 'Unnamed pet');
        final location = field('location', 'Not specified');
        final type = field('postType', 'Stray');
        final description = field(
          'description',
          'No description provided.',
        );
        final imageUrl = field('imageUrl', '');

        return Scaffold(
          backgroundColor: cream,
          appBar: AppBar(
            title: const Text('Animal Details'),
            backgroundColor: cream,
            foregroundColor: dark,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 300,
                  child: imageUrl.isEmpty
                      ? _imagePlaceholder()
                      : Image.network(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) {
                            return _imagePlaceholder();
                          },
                        ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                name,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: dark,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: orange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(
                        fontSize: 16,
                        color: dark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(
                    Icons.pets_rounded,
                    color: orange,
                    size: 18,
                  ),
                  label: Text(type),
                  backgroundColor: const Color(0xFFF7DCA2),
                  side: BorderSide.none,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'About this animal',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: dark,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: dark,
                ),
              ),
              const SizedBox(height: 32),

              
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TenderCareScreen(
            postId: postId,
            animalName: name,
          ),
        ),
      );
    },
    icon: const Icon(Icons.volunteer_activism_rounded),
    label: const Text('Provide Care'),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFBF5700),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
),


const SizedBox(height: 12),

// Support PAWLY donation button
SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const DonationScreen(),
        ),
      );
    },
    icon: const Icon(Icons.favorite_rounded),
    label: const Text('Support PAWLY'),
    style: OutlinedButton.styleFrom(
      foregroundColor: orange,
      side: const BorderSide(
        color: orange,
        width: 1.5,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
),

const SizedBox(height: 12),

// Keep the existing adoption button
if (type.toLowerCase() == 'adoption')
  SizedBox(

                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ApplyAdoptionScreen(
                            petId: postId,
                            petName: name,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.favorite_rounded),
                    label: const Text('Apply for Adoption'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                    
                    ),
                  ),
                ),

              // Report Post button
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReportPostScreen(
                          postId: postId,
                          animalName: name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Report Post'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9B3D28),
                    side: const BorderSide(
                      color: Color(0xFF9B3D28),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      },
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF7DCA2),
      child: const Center(
        child: Icon(
          Icons.pets_rounded,
          size: 70,
          color: orange,
        ),
      ),
    );
  }

  Widget _messageScreen(String message) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Animal Details'),
        backgroundColor: cream,
      ),
      body: Center(child: Text(message)),
    );
  }
}