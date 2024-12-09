import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking_spot.dart';

class FirestoreHelper {
  final CollectionReference parkingSpotsCollection =
      FirebaseFirestore.instance.collection('parking_spots');

  Future<void> saveParkingSpot(ParkingSpot spot) async {
    await parkingSpotsCollection.doc(spot.id).set(spot.toMap());
  }

  Future<void> updateParkingSpot(ParkingSpot spot) async {
    await parkingSpotsCollection.doc(spot.id).update(spot.toMap());
  }

  Future<void> deleteParkingSpot(String id) async {
    await parkingSpotsCollection.doc(id).delete();
  }

  Future<List<ParkingSpot>> fetchParkingSpots() async {
    QuerySnapshot snapshot = await parkingSpotsCollection.get();
    return snapshot.docs.map((doc) {
      return ParkingSpot.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Future<ParkingSpot?> getParkingSpotById(String id) async {
    DocumentSnapshot doc = await parkingSpotsCollection.doc(id).get();
    if (doc.exists) {
      return ParkingSpot.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
}
