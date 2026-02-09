import 'package:e_commerce_2/features/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------- Providers (UNCHANGED) ----------------
final supabaseProvider =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);

// ---------------- SignUp Notifier (UNCHANGED) ----------------
class SignUpNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseClient supabase;
  SignUpNotifier(this.supabase) : super(const AsyncValue.data(null));

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required Function(String) onError,
    required Function() onSuccess,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final response = await supabase.auth.signUp(
          email: email.trim(),
          password: password,
        );

        if (response.user == null) {
          throw Exception('Sign up failed');
        }

        await supabase.from('profiles').update({
          'username': username.trim(),
        }).eq('id', response.user!.id);

        onSuccess();
      } catch (e, stackTrace) {
        onError(e.toString());
        state = AsyncValue.error(e, stackTrace);
      }
    });
  }
}

// ---------------- Provider (UNCHANGED) ----------------
final signUpProvider =
    StateNotifierProvider<SignUpNotifier, AsyncValue<void>>((ref) {
  return SignUpNotifier(ref.watch(supabaseProvider));
});

// ---------------- UI ----------------
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signUpState = ref.watch(signUpProvider);
    final isLoading = signUpState.isLoading;

    ref.listen<AsyncValue<void>>(signUpProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red.shade600,
          ),
        ),
      );
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -------- Icon / Title --------
              const Icon(
                Icons.person_add_alt_1_rounded,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Join and start chatting',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // -------- Email --------
              _InputField(
                controller: _emailController,
                hint: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // -------- Username --------
              _InputField(
                controller: _usernameController,
                hint: 'Username',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              // -------- Password --------
              _InputField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 28),

              // -------- Sign Up Button --------
              SizedBox(
                height: 48,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () {
                          ref.read(signUpProvider.notifier).signUp(
                                email: _emailController.text,
                                password: _passwordController.text,
                                username: _usernameController.text,
                                onError: (_) {},
                                onSuccess: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Sign up successful!'),
                                    ),
                                  );
                                },
                              );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // -------- Login Redirect --------
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Already have an account? Login',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Reusable Input ----------------
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
