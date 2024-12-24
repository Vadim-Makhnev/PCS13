import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_model.dart';

class ProductDetail extends StatelessWidget {
  final Game game;

  const ProductDetail({Key? key, required this.game}) : super(key: key);

  void _showEditGameDialog(BuildContext context, Game game) {
    final TextEditingController nameController = TextEditingController(text: game.name);
    final TextEditingController descriptionController = TextEditingController(text: game.description);
    final TextEditingController priceController = TextEditingController(text: game.price.toString());
    final TextEditingController imageUrlController = TextEditingController(text: game.imageUrl);
    final TextEditingController genreController = TextEditingController(text: game.genre);
    final TextEditingController developerController = TextEditingController(text: game.developer);
    final TextEditingController platformController = TextEditingController(text: game.platform);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Редактировать игру'),
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
                  decoration: const InputDecoration(labelText: 'Ссылка на изображение'),
                ),
                TextField(
                  controller: genreController,
                  decoration: const InputDecoration(labelText: 'Жанр'),
                ),
                TextField(
                  controller: developerController,
                  decoration: const InputDecoration(labelText: 'Разработчик'),
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
              child: const Text('Отмена'),
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

                if (name.isEmpty ||
                    description.isEmpty ||
                    price == null ||
                    imageUrl.isEmpty ||
                    genre.isEmpty ||
                    developer.isEmpty ||
                    platform.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пожалуйста, заполните все поля')),
                  );
                  return;
                }

                final updatedGame = Game(
                  id: game.id,
                  name: name,
                  description: description,
                  price: price,
                  imageUrl: imageUrl,
                  genre: genre,
                  developer: developer,
                  platform: platform,
                );

                try {
                  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
                      .collection('games')
                      .where('id', isEqualTo: game.id)
                      .get();

                  if (querySnapshot.docs.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('games')
                        .doc(querySnapshot.docs.first.id)
                        .update(updatedGame.toJson());
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Игра успешно обновлена')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Документ не найден')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(game.name),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditGameDialog(context, game);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              game.imageUrl,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                game.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '${game.price.toStringAsFixed(2)} \$',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                game.description,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Text(
                    'Жанр: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    game.genre,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Text(
                    'Разработчик: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    game.developer,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Text(
                    'Платформа: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    game.platform,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
