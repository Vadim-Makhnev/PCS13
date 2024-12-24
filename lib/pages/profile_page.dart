import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'orders_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoginMode = true;
  Map<String, dynamic>? _userData;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _avatarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkUser();
    _setLocale();
  }

  void _setLocale() {
    FirebaseAuth.instance.setLanguageCode('ru');
  }

  Future<void> _checkUser() async {
    final user = _auth.currentUser;

    if (user != null) {
      setState(() {
        _user = user;
      });

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data();
        });
        _nameController.text = _userData?['name'] ?? '';
        _phoneController.text = _userData?['phone'] ?? '';
        _avatarController.text = _userData?['avatarUrl'] ?? '';
        _emailController.text = _userData?['email'] ?? '';
      }
    }
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showError('Заполните все поля');
      return;
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Вход успешен!')));
      _checkUser();
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
    } catch (e) {
      _showError('Неизвестная ошибка: $e');
    }
  }

  Future<void> _register() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      _showError('Все поля обязательны для заполнения');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Пароли не совпадают');
      return;
    }

    if (_passwordController.text.trim().length < 6) {
      _showError('Пароль должен быть не менее 6 символов');
      return;
    }

    try {
      final UserCredential? credential = await _createUser();
      if (credential == null || credential.user == null) {
        throw Exception('Ошибка: пользователь не был создан.');
      }

      final user = credential.user!;
      final userData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'avatarUrl': '',
        'isAdmin': false,
        'email': _emailController.text.trim(),
      };

      await _firestore.collection('users').doc(user.uid).set(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Регистрация успешна!')),
      );

      await _checkUser();
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
    } catch (e) {
      _showError('Неизвестная ошибка: $e');
    }
  }

  Future<UserCredential?> _createUser() async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      return credential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (_user == null || _userData == null) return;

    try {
      final updatedData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'avatarUrl': _avatarController.text.trim(),
        'email': _emailController.text.trim(),
      };

      await _firestore.collection('users').doc(_user!.uid).update(updatedData);

      if (_user!.email != _emailController.text.trim()) {
        await _auth.currentUser!.verifyBeforeUpdateEmail(_emailController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('На новый email отправлено письмо для подтверждения.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль обновлён!')),
        );
      }

      setState(() {
        _userData = updatedData;
      });
    } catch (e) {
      _showError('Не удалось обновить профиль.');
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    setState(() {
      _user = null;
      _userData = null;
    });
  }

  void _handleAuthException(FirebaseAuthException e) {
    String errorMessage;
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'Пользователь не найден.';
        break;
      case 'wrong-password':
        errorMessage = 'Неверный пароль.';
        break;
      case 'email-already-in-use':
        errorMessage = 'Этот email уже зарегистрирован.';
        break;
      case 'invalid-email':
        errorMessage = 'Неверный формат email.';
        break;
      case 'weak-password':
        errorMessage = 'Пароль слишком слабый.';
        break;
      default:
        errorMessage = 'Ошибка: ${e.message}';
    }
    _showError(errorMessage);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Game Store', style: TextStyle(fontSize: 30),),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
            ),
          ],
          backgroundColor: Colors.blueGrey,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Изменить аватар'),
                          content: TextField(
                            controller: _avatarController,
                            decoration: const InputDecoration(labelText: 'URL изображения'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                _updateProfile();
                                Navigator.of(context).pop();
                              },
                              child: const Text('Сохранить'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _userData?['avatarUrl']?.isNotEmpty == true
                        ? NetworkImage(_userData!['avatarUrl'])
                        : null,
                    child: _userData?['avatarUrl']?.isNotEmpty == true
                        ? null
                        : const Icon(Icons.perm_contact_cal, size: 50),
                  ),
                ),
                const SizedBox(height: 100),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Имя'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Телефон'),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(top: 250), // Добавляем отступ сверху
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    child: const Text(
                      'Сохранить изменения',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(top: 10), // Добавляем отступ сверху
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OrdersPage()),
                      );
                    },
                    child: const Text(
                      'Мои заказы',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Вход / Регистрация'), backgroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoginMode ? _buildLoginForm() : _buildRegisterForm(),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Пароль'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _login,
          child: const Text('Войти'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _isLoginMode = false;
            });
          },
          child: const Text('Нет аккаунта? Зарегистрироваться'),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Имя'),
        ),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Телефон'),
        ),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Пароль'),
        ),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Подтверждение пароля'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _register,
          child: const Text('Зарегистрироваться'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _isLoginMode = true;
            });
          },
          child: const Text('Уже есть аккаунт? Войти'),
        ),
      ],
    );
  }
}
