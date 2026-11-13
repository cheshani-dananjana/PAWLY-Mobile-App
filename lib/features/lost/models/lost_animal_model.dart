import 'package:cloud_firestore/cloud_firestore.dart';

class LostAnimalModel {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String? imageUrl;

  LostAnimalModel({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
  });

  factory LostAnimalModel.fromMap(Map<String, dynamic> map, String documentId) {
    return LostAnimalModel(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      imageUrl: map['image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
    };
  }
}
