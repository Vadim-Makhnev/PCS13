import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_model.dart';
import '../api_service.dart';
import '../pages/product_detail.dart';
import '../pages/chat_page.dart';
import '../provider/cart_favorite_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _currentUser;
  List<Game> _allGames = [];
  List<Game> _filteredGames = [];
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    setState(() {
      _currentUser = FirebaseAuth.instance.currentUser;
    });
    if (_currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get()
          .then((doc) {
        if (doc.exists && doc.data()?['isAdmin'] == true) {
          setState(() {
            _isAdmin = true;
          });
        }
      });
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatPage(),
      ),
    );
  }

  void _filterGames(String query) {
    setState(() {
      _filteredGames = _allGames
          .where((game) =>
      game.name.toLowerCase().contains(query.toLowerCase()) ||
          game.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  String _generateRandomId() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return (random % 90000 + 10000).toString();
  }

  void _showAddGameDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController imageUrlController = TextEditingController();
    final TextEditingController genreController = TextEditingController();
    final TextEditingController developerController = TextEditingController();
    final TextEditingController platformController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Добавить игру'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Название'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Описание'),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Цена'),
                ),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(labelText: 'Ссылка на картинку'),
                ),
                TextField(
                  controller: genreController,
                  decoration: const InputDecoration(labelText: 'Жанр'),
                ),
                TextField(
                  controller: developerController,
                  decoration: const InputDecoration(labelText: 'Разработчики'),
                ),
                TextField(
                  controller: platformController,
                  decoration: const InputDecoration(labelText: 'Платформа'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Отмена', style: TextStyle(color: Colors.black),),
            ),
            TextButton(
              onPressed: () async {
                final String name = nameController.text.trim();
                final String description = descriptionController.text.trim();
                final double? price = double.tryParse(priceController.text.trim());
                final String imageUrl = imageUrlController.text.trim();
                final String genre = genreController.text.trim();
                final String developer = developerController.text.trim();
                final String platform = platformController.text.trim();

                if (name.isEmpty || description.isEmpty || price == null || imageUrl.isEmpty || genre.isEmpty || developer.isEmpty || platform.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пожалуйста, заполните все поля')),
                  );
                  return;
                }

                final String id = _generateRandomId();

                final game = Game(
                  id: id,
                  name: name,
                  description: description,
                  price: price,
                  imageUrl: imageUrl,
                  genre: genre,
                  developer: developer,
                  platform: platform,
                );

                try {
                  await ApiService().createGame(game);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Игра успешно добавлена')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              },
              child: const Text('Добавить', style: TextStyle(color: Colors.black),),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: AppBar(
          title: _isSearching
              ? TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Поиск...'),
            onChanged: _filterGames,
          )
         : Text(
          'Game Store', // Store name
          style: TextStyle(
            color: Colors.black,
            fontSize: 35,
            fontWeight: FontWeight.bold,
          ),
        ),
          backgroundColor: Colors.blueGrey,
          actions: [
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: _currentUser == null ? null : _openChat,
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _filteredGames = _allGames;
                  }
                });
              },
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () {
          if (_isSearching) {
            setState(() {
              _isSearching = false;
              _searchController.clear();
              _filteredGames = _allGames;
            });
          }
        },
        child: StreamBuilder<List<Game>>(
          stream: FirebaseFirestore.instance
              .collection('games')
              .snapshots()
              .map((snapshot) => snapshot.docs
              .map((doc) => Game.fromJson(doc.data() as Map<String, dynamic>))
              .toList()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Ошибка: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Игры не найдены.'));
            }

            _allGames = snapshot.data!;
            if (_filteredGames.isEmpty) {
              _filteredGames = _allGames;
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _filteredGames = _allGames;
                });
              },
              child: GridView.builder(
                padding: const EdgeInsets.all(15.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: _filteredGames.length,
                itemBuilder: (context, index) {
                  final game = _filteredGames[index];
                  final isFavorite = context.watch<CartFavoriteProvider>().isFavorite(game);
                  final isInCart = context.watch<CartFavoriteProvider>().isInCart(game);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetail(game: game),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 5,
                      color: Colors.grey[850],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: Image.network(
                              game.imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              game.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '${game.price.toStringAsFixed(2)} \$',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: () {
                                    if (isFavorite) {
                                      context.read<CartFavoriteProvider>().removeFromFavorites(game);
                                    } else {
                                      context.read<CartFavoriteProvider>().addToFavorites(game);
                                    }
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
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        onPressed: _showAddGameDialog,
        child: const Icon(Icons.add, color: Colors.white70,),
      )
          : null,
    );
  }
}
