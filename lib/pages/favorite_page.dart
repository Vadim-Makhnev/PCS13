import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/cart_favorite_provider.dart';
import '../models/game_model.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favoriteItems = context.watch<CartFavoriteProvider>().favoriteItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Store', style: TextStyle(color: Colors.black, fontSize: 30),),
        backgroundColor: Colors.blueGrey,
      ),
      backgroundColor: Colors.grey[700],
      body: favoriteItems.isEmpty
          ? const Center(
        child: Text(
          'Список любимых игр пуст.',
          style: TextStyle(color: Colors.white),
        ),
      )
          : ListView.builder(
        itemCount: favoriteItems.length,
        itemBuilder: (context, index) {
          final game = favoriteItems[index];
          final isInCart = context.watch<CartFavoriteProvider>().isInCart(game);

          return ListTile(
            leading: Image.network(game.imageUrl, width: 50, height: 50),
            title: Text(
              game.name,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Цена: ${game.price.toStringAsFixed(2)} ₽',
                  style: const TextStyle(color: Colors.grey),
                ),
                if (isInCart)
                  const Text(
                    'Уже в корзине',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () {
                    context.read<CartFavoriteProvider>().removeFromFavorites(game);
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.shopping_cart,
                    color: isInCart ? Colors.yellowAccent : Colors.grey,
                  ),
                  onPressed: () {
                    if (isInCart) {
                      context.read<CartFavoriteProvider>().removeFromCart(game);
                    } else {
                      context.read<CartFavoriteProvider>().addToCart(game);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
