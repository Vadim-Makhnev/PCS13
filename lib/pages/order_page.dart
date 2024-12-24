import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../provider/cart_favorite_provider.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _addressController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _submitOrder() async {
    final cartProvider = context.read<CartFavoriteProvider>();
    final cartItems = cartProvider.cartItems;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы не авторизованы')),
      );
      return;
    }

    if (_addressController.text.trim().isEmpty || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userName = userDoc.data()?['name'] ?? 'Имя не указано';
        final userPhone = userDoc.data()?['phone'] ?? 'Телефон не указан';

        final orderData = {
          'userId': user.uid,
          'userName': userName,
          'userPhone': userPhone,
          'address': _addressController.text.trim(),
          'date': _selectedDate.toString(),
          'time': _selectedTime?.format(context),
          'items': cartItems.map((item) => item.toJson()).toList(),
          'createdAt': Timestamp.now(),
        };

        await FirebaseFirestore.instance.collection('orders').add(orderData);

        cartProvider.clearCart();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ успешно оформлен!')),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось получить данные пользователя')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка оформления заказа: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформление заказа'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Container(
        color: Colors.grey[700],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Адрес доставки игры',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey,
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _selectedDate == null
                      ? 'Выберите дату доставки'
                      : 'Дата доставки: ${_selectedDate.toString().split(' ')[0]}',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.white),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _selectedTime == null
                      ? 'Выберите время доставки'
                      : 'Время доставки: ${_selectedTime?.format(context)}',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.access_time, color: Colors.white),
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _selectedTime = pickedTime;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: _submitOrder,
                child: const Text(
                  'Оформить заказ',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
