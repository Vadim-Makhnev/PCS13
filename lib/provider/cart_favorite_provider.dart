import 'package:flutter/material.dart';
import '../models/game_model.dart';

class CartFavoriteProvider extends ChangeNotifier {
  final List<Game> _cartItems = [];
  final List<Game> _favoriteItems = [];

  List<Game> get cartItems => _cartItems;
  List<Game> get favoriteItems => _favoriteItems;

  void addToCart(Game game) {
    final index = _cartItems.indexWhere((item) => item.id == game.id);
    if (index == -1) {
      _cartItems.add(game.copyWith(quantity: 1));
    } else {
      final updatedItem = _cartItems[index].copyWith(
        quantity: _cartItems[index].quantity! + 1,
      );
      _cartItems[index] = updatedItem;
    }
    notifyListeners();
  }

  void removeFromCart(Game game) {
    _cartItems.removeWhere((item) => item.id == game.id);
    notifyListeners();
  }

  void updateQuantity(Game game, int quantity) {
    final index = _cartItems.indexWhere((item) => item.id == game.id);
    if (index != -1) {
      if (quantity <= 0) {
        removeFromCart(game);
      } else {
        _cartItems[index] = game.copyWith(quantity: quantity);
        notifyListeners();
      }
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  void addToFavorites(Game game) {
    if (!_favoriteItems.contains(game)) {
      _favoriteItems.add(game);
      notifyListeners();
    }
  }

  void removeFromFavorites(Game game) {
    _favoriteItems.remove(game);
    notifyListeners();
  }

  bool isFavorite(Game game) {
    return _favoriteItems.contains(game);
  }

  bool isInCart(Game game) {
    return _cartItems.any((item) => item.id == game.id);
  }
}
