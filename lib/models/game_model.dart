class Game {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final String developer;
  final String genre;
  final String platform;
  final int? quantity;

  Game({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.developer,
    required this.genre,
    required this.platform,
    this.quantity,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      price: (json['price'] as num).toDouble(),
      developer: json['developer'] as String,
      genre: json['genre'] as String,
      platform: json['platform'] as String,
      quantity: json['quantity'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'developer': developer,
      'genre': genre,
      'platform': platform,
      'quantity': quantity,
    };
  }

  Game copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    double? price,
    String? developer,
    String? genre,
    String? platform,
    int? quantity,
  }) {
    return Game(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      developer: developer ?? this.developer,
      genre: genre ?? this.genre,
      platform: platform ?? this.platform,
      quantity: quantity ?? this.quantity,
    );
  }
}
