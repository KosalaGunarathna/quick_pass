import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/auth_bloc.dart';

const brandBlue = Color(0xFF1F5FA6);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool obscure = true;
  bool remember = false;

  @override
  void initState() {
    super.initState();
    loadRemember();
  }

  Future<void> loadRemember() async {
    final prefs = await SharedPreferences.getInstance();

    remember = prefs.getBool('remember') ?? false;

    if (remember) {
      _email.text = prefs.getString('email') ?? '';
    }

    setState(() {});
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();

    if (remember) {
      await prefs.setString('email', _email.text.trim());
      await prefs.setBool('remember', true);
    } else {
      await prefs.clear();
    }

    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go(state.user.isOrganizer ? '/organizer' : '/home');
          }

          if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        'QuickPass',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: brandBlue,
                        ),
                      ),

                      Image.asset(
                        'assets/icons/app_icon.png',
                        width: 70,
                        height: 70,
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'john@gmail.com',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Enter email';
                          }

                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                            return 'Invalid email';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      TextFormField(
                        controller: _pass,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() => obscure = !obscure);
                            },
                          ),
                        ),
                        validator: (v) => v != null && v.length >= 6
                            ? null
                            : 'Minimum 6 characters',
                      ),

                      Row(
                        children: [
                          Checkbox(
                            value: remember,
                            onChanged: (v) {
                              setState(() => remember = v ?? false);
                            },
                          ),
                          const Text('Remember me'),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Forgot Password?'),
                          ),
                        ],
                      ),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(loading ? 'Loading...' : 'Login'),
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          context.push('/register');
                        },
                        child: const Text("Don't have an account? Sign Up"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
