import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';
import 'register.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const GrainGuardApp());
}

class GrainGuardApp extends StatelessWidget {
  const GrainGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrainGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Define a primary color for consistent branding
        primarySwatch: Colors.green, // This will generate various shades of green
        primaryColor: const Color(0xFF4CAF50), // Explicitly define your desired green
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light grey background
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4CAF50), // Green app bar
          foregroundColor: Colors.white, // White text/icons on app bar
          elevation: 4.0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0), // More rounded corners
            borderSide: BorderSide.none, // No border by default
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2.0), // Green border when focused
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0), // Light grey border when enabled
          ),
          labelStyle: const TextStyle(color: Color(0xFF555555)), // Darker grey label
          hintStyle: const TextStyle(color: Color(0xFF555555)), // Darker grey hint
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0), // More padding
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50), // Green button background
            foregroundColor: Colors.white, // White text on button
            padding: const EdgeInsets.symmetric(vertical: 18), // Taller button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Rounded button corners
            ),
            elevation: 5, // Add shadow to the button
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Larger, bold text
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF4CAF50), // Green text button
            textStyle: const TextStyle(fontWeight: FontWeight.bold), // Bold text button
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoggedIn = false;
  String _userId = '';

  void _login(String userId) {
    setState(() {
      _isLoggedIn = true;
      _userId = userId;
    });
  }

  void _logout() => setState(() {
        _isLoggedIn = false;
        _userId = '';
      });

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn
        ? HomeScreen(onLogout: _logout, userId: _userId)
        : LoginScreen(onLogin: _login);
  }
}

class LoginScreen extends StatefulWidget {
  final Function(String) onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('name', isEqualTo: _usernameController.text)
          .where('password', isEqualTo: _passwordController.text)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _errorMessage = 'Invalid username or password';
        });
        return;
      }

      // Get the user document ID and pass it to onLogin
      final userId = querySnapshot.docs.first.id;
      widget.onLogin(userId);
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RegisterScreen(
          onRegister: () => widget.onLogin(''), // Temporary empty user ID
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'GRAINGUARD',
                  style: TextStyle(
                    fontSize: 32, // Slightly larger
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor, // Use primary color
                    fontStyle: FontStyle.normal, // Not cursive
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).primaryColor, // Use primary color
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold), // Darker red and bold
                    ),
                  ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person, color: Colors.grey), // Add icon
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock, color: Colors.grey), // Add icon
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility, color: Colors.grey.shade600,), // Icon color
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _navigateToRegister,
                          child: const Text('Register'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('LOGIN'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}