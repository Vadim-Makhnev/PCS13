import 'package:flutter/material.dart';
import 'game_model.dart';

class GameProvider extends ChangeNotifier {
  final List<Game> _cart = [];
  final List<Game> _favorites = [];

  List<Game> get cart => _cart;
  List<Game> get favorites => _favorites;

  void addToCart(Game game) {
    if (!_cart.contains(game)) {
      _cart.add(game);
      notifyListeners();
    }
  }

  void removeFromCart(Game game) {
    _cart.remove(game);
    notifyListeners();
  }

  void addToFavorites(Game game) {
    if (!_favorites.contains(game)) {
      _favorites.add(game);
      notifyListeners();
    }
  }

  void removeFromFavorites(Game game) {
    _favorites.remove(game);
    notifyListeners();
  }
}
