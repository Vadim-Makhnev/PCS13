import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool? isAdmin;
  String? userId;
  String? currentChatId;
  List<Map<String, dynamic>> chats = [];

  @override
  void initState() {
    super.initState();
    _initializeChatPage();
  }

  Future<void> _initializeChatPage() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        print('[DEBUG] Пользователь не авторизован.');
        return;
      }

      userId = user.uid;
      print('[DEBUG] Текущий пользователь: $userId');

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('[DEBUG] Документ пользователя не найден.');
        return;
      }

      isAdmin = userDoc.data()?['isAdmin'] ?? false;
      print('[DEBUG] Пользователь администратор: $isAdmin');

      if (isAdmin!) {
        print('[DEBUG] Загружаем список чатов для администратора...');
        await _loadAdminChats();
      } else {
        print('[DEBUG] Загружаем чат с администратором...');
        await _loadUserChat();
      }
    } catch (e) {
      print('[ERROR] Ошибка инициализации страницы чата: $e');
    }
  }

  Future<void> _loadAdminChats() async {
    try {
      final chatsQuery = await _firestore.collection('chats').get();
      if (chatsQuery.docs.isEmpty) {
        print('[DEBUG] У администратора нет доступных чатов.');
        return;
      }

      chats = chatsQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {});
    } catch (e) {
      print('[ERROR] Ошибка загрузки чатов администратора: $e');
    }
  }

  Future<void> _loadUserChat() async {
    try {
      final userChatQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      if (userChatQuery.docs.isEmpty) {
        print('[DEBUG] У пользователя нет чатов. Создаем новый...');
        final newChat = {
          'participants': [userId, 'adminUserId'],
          'createdAt': FieldValue.serverTimestamp(),
        };

        final newChatRef = await _firestore.collection('chats').add(newChat);
        currentChatId = newChatRef.id;
        print('[DEBUG] Новый чат создан с ID: $currentChatId');
      } else {
        final chat = userChatQuery.docs.first;
        currentChatId = chat.id;
        print('[DEBUG] Найден существующий чат с ID: $currentChatId');
      }

      setState(() {});
    } catch (e) {
      print('[ERROR] Ошибка загрузки чата пользователя: $e');
    }
  }

  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['name'] ?? 'Неизвестный пользователь';
    } catch (e) {
      print('[ERROR] Ошибка получения имени пользователя: $e');
      return 'Неизвестный пользователь';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isAdmin == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (isAdmin!) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Чаты с клиентами'),
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.grey[900],
        body: chats.isEmpty
            ? const Center(
          child: Text(
            'Нет доступных чатов.',
            style: TextStyle(color: Colors.white),
          ),
        )
            : ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final lastMessage = chat['lastMessage'] ?? 'Нет сообщений';

            return FutureBuilder<String>(
              future: _getUserName(chat['participants'].firstWhere(
                    (participant) => participant != userId,
                orElse: () => 'Неизвестный пользователь',
              )),
              builder: (context, snapshot) {
                final userName =
                snapshot.connectionState == ConnectionState.done
                    ? snapshot.data
                    : 'Загрузка...';

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueGrey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    'Чат с $userName',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    lastMessage,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailPage(
                          chatId: chat['id'],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      );
    } else {
      if (currentChatId == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return ChatDetailPage(chatId: currentChatId!);
    }
  }
}
