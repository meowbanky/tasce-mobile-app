// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/validators.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isFirstSubmit = false;
  bool _rememberLogin = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _biometricType = 'Biometric';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _loadRememberedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAvailable = await authProvider.isBiometricAvailable();
    final isEnabled = await authProvider.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _biometricAvailable = isAvailable;
        _biometricEnabled = isEnabled;
      });

      if (isAvailable) {
        final biometrics = await authProvider.getAvailableBiometrics();
        if (biometrics.isNotEmpty) {
          setState(() {
            if (biometrics.contains('fingerprint')) {
              _biometricType = 'Fingerprint';
            } else if (biometrics.contains('face')) {
              _biometricType = 'Face ID';
            } else if (biometrics.contains('iris')) {
              _biometricType = 'Iris';
            }
          });
        }
      }
    }
  }

  Future<void> _loadRememberedCredentials() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final credentials = await authProvider.getRememberedCredentials();

    if (mounted && credentials['email'] != null) {
      setState(() {
        _emailController.text = credentials['email']!;
        _passwordController.text = credentials['password'] ?? '';
        _rememberLogin = true;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isFirstSubmit = true;
    });

    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final response = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (response['success'] == true) {
        // Save remember login if checked
        await authProvider.saveRememberLogin(
          _rememberLogin,
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // Ask user if they want to enable biometric login
        if (_biometricAvailable && !_biometricEnabled) {
          _showBiometricSetupDialog();
        } else {
          _showSuccessSnackBar('Login successful! Welcome back.');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        _showErrorSnackBar(
            response['message'] ?? 'Login failed. Please try again.');
      }
    } catch (e) {
      if (e.toString().contains('Connection error')) {
        _showErrorSnackBar(
            'Unable to connect to server. Please check your internet connection.');
      } else if (e.toString().contains('timeout')) {
        _showErrorSnackBar('Connection timeout. Please try again.');
      } else {
        _showErrorSnackBar(
            'An unexpected error occurred. Please try again later.');
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final response = await authProvider.loginWithBiometric();

      if (!mounted) return;

      if (response['success'] == true) {
        _showSuccessSnackBar('Login successful! Welcome back.');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        _showErrorSnackBar(
            response['message'] ?? 'Biometric login failed. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Biometric authentication failed. Please try again.');
    }
  }

  void _showBiometricSetupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enable $_biometricType Login?'),
          content: Text(
            'Would you like to enable $_biometricType login for faster access? You can change this later in settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccessSnackBar('Login successful! Welcome back.');
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => const DashboardScreen()),
                );
              },
              child: const Text('Not Now'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                await authProvider.saveBiometricCredentials(
                  _emailController.text.trim(),
                  _passwordController.text.trim(),
                );
                setState(() {
                  _biometricEnabled = true;
                });
                _showSuccessSnackBar(
                    '$_biometricType login enabled! Welcome back.');
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => const DashboardScreen()),
                );
              },
              child: const Text('Enable'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) => SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _isFirstSubmit
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      Hero(
                        tag: 'college_logo',
                        child: Image.asset(
                          'assets/images/tasce_r_logo.png',
                          height: 120,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'SIKIRU ADETONA COLLEGE OF EDUCATION',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        'SCIENCE AND TECHNOLOGY',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 40),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Login',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: const Icon(Icons.email_outlined),
                                hintText: 'Enter your email address',
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: Validators.validateEmail,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                hintText: 'Enter your password',
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                helperText: '',
                                helperMaxLines: 2,
                              ),
                              // validator: Validators.validatePassword,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberLogin,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberLogin = value ?? false;
                                    });
                                  },
                                  activeColor: AppTheme.primaryColor,
                                ),
                                Expanded(
                                  child: const Text('Remember my login'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                  ),
                                  child: const Text('Forgot Password?'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: auth.isLoading
                                    ? const SpinKitThreeBounce(
                                        color: Colors.white,
                                        size: 24,
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            if (_biometricAvailable && _biometricEnabled) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: auth.isLoading
                                      ? null
                                      : _handleBiometricLogin,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                    side: BorderSide(
                                        color: AppTheme.primaryColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Icon(
                                    _biometricType == 'Fingerprint'
                                        ? Icons.fingerprint
                                        : _biometricType == 'Face ID'
                                            ? Icons.face
                                            : Icons.fingerprint,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: () {
                              // Handle registration
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                            ),
                            child: const Text('Register'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
