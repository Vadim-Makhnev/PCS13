import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_model.dart';

class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Game>> getGames() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('games').get();
      return snapshot.docs
          .map((doc) => Game.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching games: $e');
    }
  }

  Future<Game> getGameById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('games').doc(id).get();
      return Game.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error fetching game by ID: $e');
    }
  }

  Future<void> createGame(Game game) async {
    try {
      await _firestore.collection('games').add(game.toJson());
    } catch (e) {
      throw Exception('Error creating game: $e');
    }
  }

  Future<void> updateGame(String id, Game game) async {
    try {
      await _firestore.collection('games').doc(id).update(game.toJson());
    } catch (e) {
      throw Exception('Error updating game: $e');
    }
  }

  Future<void> deleteGame(String id) async {
    try {
      await _firestore.collection('games').doc(id).delete();
    } catch (e) {
      throw Exception('Error deleting game: $e');
    }
  }

  Stream<List<Game>> getGamesStream() {
    return _firestore.collection('games').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Game.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }
}
