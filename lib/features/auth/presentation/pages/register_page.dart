import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';

const brandBlue = Color(0xFF1F5FA6);

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
  final _contactNumberCtrl = TextEditingController();
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
    _contactNumberCtrl.dispose();
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
          contactNumber: _contactNumberCtrl.text.trim().isEmpty
              ? null
              : _contactNumberCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          role: _accountType,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const canvas = Color(0xFFF3F5F8);

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
              padding: const EdgeInsets.all(15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Form(
                  key: _registerKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Title (matches login's 'QuickPass' style) ──
                      const Text(
                        'Create account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: brandBlue,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // ── Subtitle ──
                      const Text(
                        'Set up your profile details',
                        textAlign: TextAlign.center,
                        // No explicit fontSize → inherits theme default (~14)
                      ),

                      const SizedBox(height: 16),

                      // ── Account type cards ──
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

                      // ── Full name ──
                      TextFormField(
                        controller: _fullNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          hintText: 'John Doe',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter your full name'
                                : null,
                      ),

                      const SizedBox(height: 15),

                      // ── Email ──
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@company.com',
                        ),
                        validator: (value) =>
                            value == null || !value.contains('@')
                                ? 'Enter a valid email address'
                                : null,
                      ),

                      const SizedBox(height: 15),

                      // ── Contact number ──
                      TextFormField(
                        controller: _contactNumberCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Contact number',
                          hintText: '+1 555 123 4567',
                        ),
                      ),

                      const SizedBox(height: 15),

                      // ── Password ──
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Minimum 8 characters',
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.length <= 6
                                ? 'Minimum 6 characters'
                                : null,
                      ),

                      // ── Terms checkbox (matches login's remember-me row) ──
                      Row(
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            onChanged: (v) =>
                                setState(() => _acceptTerms = v ?? false),
                          ),
                          const Expanded(
                            child: Text(
                              'I agree to the Terms of Service and Privacy Policy',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ── Submit button (matches login's ElevatedButton) ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submitRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            isLoading ? 'Creating...' : 'Create Account',
                          ),
                        ),
                      ),

                      // ── Sign-in link (matches login's TextButton) ──
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text(
                          'Already have an account? Sign in',
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

// ── Type card ──────────────────────────────────────────────────────────────

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
    final borderColor =
        isSelected ? const Color(0xFF5E35B1) : const Color(0xFFD8D8D8);
    final backgroundColor =
        isSelected ? const Color(0xFFF4F8FD) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Column(
          children: [
            // Large letter — kept at 24 to visually match the title size
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? brandBlue : const Color(0xFF141414),
              ),
            ),
            const SizedBox(height: 6),
            // Subtitle — no explicit size, inherits theme default
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            // Description — one step smaller but still readable (12)
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}