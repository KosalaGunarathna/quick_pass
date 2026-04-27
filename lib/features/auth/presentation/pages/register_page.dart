import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.initialRole = 'user'});

  final String initialRole;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _registerKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _acceptTerms = false;
  late String _accountType;

  @override
  void initState() {
    super.initState();
    _accountType = widget.initialRole == 'organizer' ? 'organizer' : 'user';
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submitRegister() {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms before creating an account.'),
        ),
      );
      return;
    }

    if (_registerKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          name: _fullNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          role: _accountType,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const canvas = Color(0xFFF3F5F8);
    const brandBlue = Color(0xFF1F5FA6);

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        foregroundColor: const Color(0xFF1A2433),
        elevation: 0,
        centerTitle: true,
        title: const Text('Create account'),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            if (state.user.isOrganizer) {
              context.go('/organizer');
            } else {
              context.go('/home');
            }
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD9D9D9)),
                ),
                child: Form(
                  key: _registerKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF151515),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Set up your profile details',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF76808D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _TypeCard(
                              isSelected: _accountType == 'user',
                              title: 'U',
                              subtitle: 'User',
                              description: 'Book tickets',
                              onTap: () =>
                                  setState(() => _accountType = 'user'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TypeCard(
                              isSelected: _accountType == 'organizer',
                              title: 'O',
                              subtitle: 'Organizer',
                              description: 'Create events',
                              onTap: () =>
                                  setState(() => _accountType = 'organizer'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel('Full name'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _fullNameCtrl,
                        decoration: const InputDecoration(hintText: 'John Doe'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter your full name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      const _FieldLabel('Email address'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'you@company.com',
                        ),
                        validator: (value) =>
                            value == null || !value.contains('@')
                            ? 'Enter a valid email address'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      const _FieldLabel('Password'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          hintText: 'Minimum 8 characters',
                          suffixIcon: IconButton(
                            onPressed: () => setState(() {
                              _obscure = !_obscure;
                            }),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF8B96A5),
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.length < 8
                            ? 'Minimum 8 characters'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: _acceptTerms,
                        onChanged: (value) => setState(() {
                          _acceptTerms = value ?? false;
                        }),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: const Text(
                          'I agree to the Terms of Service and Privacy Policy',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ActionButton(
                        label: isLoading ? 'Creating...' : 'Create Account',
                        onPressed: isLoading ? null : _submitRegister,
                        color: brandBlue,
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/login'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Already have an account? Sign in',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
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

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.isSelected,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onTap,
  });

  final bool isSelected;
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? const Color(0xFF5E35B1)
        : const Color(0xFFD8D8D8);
    final backgroundColor = isSelected ? const Color(0xFFF4F8FD) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor, width: isSelected ? 1.4 : 1),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF1F5FA6)
                    : const Color(0xFF141414),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF141414),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8.5, color: Color(0xFF7B8490)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6F7783),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
