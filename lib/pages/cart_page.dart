import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/cart_favorite_provider.dart';
import 'order_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartItems = context.watch<CartFavoriteProvider>().cartItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Store', style: TextStyle(color: Colors.black, fontSize: 30),),
        backgroundColor: Colors.blueGrey,
      ),
      backgroundColor: Colors.grey[700],
      body: Column(
        children: [
          Expanded(
            child: cartItems.isEmpty
                ? const Center(
              child: Text(
                'Ваша корзина пуста.',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            )
                : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final game = cartItems[index];
                int quantity = game.quantity ?? 1;

                return Dismissible(
                  key: ValueKey(game.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerRight,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  onDismissed: (direction) {
                    context.read<CartFavoriteProvider>().removeFromCart(game);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${game.name} удалена из корзины'),
                        backgroundColor: Colors.grey[800],
                      ),
                    );
                  },
                  child: ListTile(
                    leading: Image.network(
                      game.imageUrl,
                      width: 50,
                      height: 50,
                    ),
                    title: Text(
                      game.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Цена: ${game.price * quantity} \$.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (quantity > 1) {
                              quantity--;
                              context.read<CartFavoriteProvider>().updateQuantity(game, quantity);
                            }
                          },
                        ),
                        Text(
                          quantity.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            quantity++;
                            context.read<CartFavoriteProvider>().updateQuantity(game, quantity);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrderPage(),
                    ),
                  );
                },
                child: const Text(
                  'Оформить заказ',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
