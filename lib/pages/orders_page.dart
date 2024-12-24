import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_details_page.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Мои заказы'),
          backgroundColor: Colors.blueGrey,
        ),
        body: const Center(
          child: Text('Пожалуйста, войдите в систему.', style: TextStyle(color: Colors.black)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
        backgroundColor: Colors.blueGrey,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (userSnapshot.hasError) {
            return Center(
              child: Text('Ошибка: ${userSnapshot.error}', style: const TextStyle(color: Colors.black)),
            );
          }

          final isAdmin = userSnapshot.data?.get('isAdmin') ?? false;

          return FutureBuilder<QuerySnapshot>(
            future: isAdmin
                ? FirebaseFirestore.instance.collection('orders').get()
                : FirebaseFirestore.instance
                .collection('orders')
                .where('userId', isEqualTo: currentUser.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Ошибка: ${snapshot.error}', style: const TextStyle(color: Colors.black)),
                );
              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('У вас нет заказов.', style: TextStyle(color: Colors.black)),
                );
              }

              final orders = snapshot.data!.docs;

              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
                  final userName = order['userName'] ?? 'Неизвестный пользователь';

                  return ListTile(
                    title: Text(
                      'Заказ от $userName',
                      style: const TextStyle(color: Colors.black),
                    ),
                    subtitle: createdAt != null
                        ? Text(
                      'Дата оформления: ${createdAt.toLocal()}',
                      style: const TextStyle(color: Colors.black),
                    )
                        : const Text('Дата оформления: неизвестно', style: TextStyle(color: Colors.black)),
                    trailing: IconButton(
                      icon: const Icon(Icons.details, color: Colors.black),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsPage(orderId: order.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
