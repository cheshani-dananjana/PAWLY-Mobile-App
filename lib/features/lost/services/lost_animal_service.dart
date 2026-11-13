import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lost_animal_model.dart';

class LostAnimalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch lost animals as a real-time stream
  Stream<List<LostAnimalModel>> getLostAnimalsStream() {
    return _db.collection('lost_animals').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return LostAnimalModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Add a new lost animal to the database
  Future<void> addLostAnimal(LostAnimalModel animal) async {
    await _db.collection('lost_animals').add(animal.toMap());
  }
}
