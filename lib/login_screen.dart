import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart';
import 'signup_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Form key
  final _formKey = GlobalKey<FormState>();

  // Colors
  final Color primaryColor = const Color(0xFF6B8068);

  // UI State
  bool _isLoading = false;
  bool _isResetLoading = false;
  bool _passwordVisible = false;

  // -------------------------------
  // Authentication Methods
  // -------------------------------

  Future<void> signIn() async {
    if (!_formKey.currentState!.validate()) return;

    _setLoading(true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    ).timeout(const Duration(seconds: 10), onTimeout: () {
      throw FirebaseAuthException(
        code: 'network-request-failed',
      );
    });
    
      _navigateToMainScreen();
    } on FirebaseAuthException catch (e) {
      _showErrorDialog("خطأ", _translateAuthError(e.code));
    } catch (_) {
      _showErrorDialog("خطأ غير متوقع", "حدثت مشكلة غير متوقعة، حاول مرة أخرى");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      _showErrorDialog("تنبيه", "الرجاء كتابة البريد الإلكتروني أولاً.");
      return;
    }

    _setResetLoading(true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
      email: emailController.text.trim(), 
      )
    .timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        throw FirebaseAuthException(
          code: 'network-request-failed',
        );
      },
    );

      _showSnackBar("تم إرسال رابط تعيين كلمة المرور بنجاح");
    } on FirebaseAuthException catch (e) {
      _showErrorDialog("خطأ", _translateAuthError(e.code));
    } finally {
      _setResetLoading(false);
    }
  }

  // -------------------------------
  // Helper Methods
  // -------------------------------
  
 String _translateAuthError(String code) {
  switch (code) {
    case 'invalid-credential':
    case 'wrong-password':
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
    case 'user-disabled':
      return 'تم تعطيل هذا الحساب.';
    case 'too-many-requests':
      return 'محاولات كثيرة خاطئة. يرجى الانتظار قليلاً.';
    case 'user-not-found':
      return 'الحساب غير موجود. يرجى التأكد من البريد الإلكتروني.';
    case 'network-request-failed':
      return 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.';
    default:
      return 'حدث خطأ غير متوقع ($code).';
  }
}
 

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text(title, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: TextStyle(color: primaryColor, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("حسناً", style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: primaryColor,
                                  content: Row( 
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white, size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                      ),
                                   ],
                                  ),
                                   elevation: 0,
                                   duration: Duration(seconds: 1),
                                ),
                              );
  }

  void _navigateToMainScreen() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainScreen()),
    );
  }

  void _setLoading(bool value) {
    if (!mounted) return;
    setState(() => _isLoading = value);
  }

  void _setResetLoading(bool value) {
    if (!mounted) return;
    setState(() => _isResetLoading = value);
  }

  // -------------------------------
  // UI
  // -------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf1f2ed),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 120),
              _buildLogo(),
              const SizedBox(height: 60),
              _buildLoginForm(),
              const SizedBox(height: 180),
              _buildSignUpLink(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo1.png',
          width: 80,
          height: 80,
          errorBuilder: (ctx, error, stack) => Icon(Icons.store, size: 80, color: primaryColor),
        ),
        const SizedBox(height: 10),
        Image.asset(
          'assets/images/logo.png',
          width: 70,
          height: 14,
          errorBuilder: (ctx, error, stack) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.85,
        child: Column(
          children: [
            _buildTitle(),
            const SizedBox(height: 15),
            _buildEmailField(),
            const SizedBox(height: 15),
            _buildPasswordField(),
            _buildResetPasswordButton(),
            const SizedBox(height: 10),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        "تسجيل الدخول",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return "الرجاء إدخال البريد الإلكتروني";
        if (!EmailValidator.validate(value.trim())) return "الرجاء إدخال بريد إلكتروني صالح";
        return null;
      },
      decoration: _buildInputDecoration("البريد الإلكتروني", Icons.email_outlined),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      obscureText: !_passwordVisible,
      validator: (val) => val != null && val.length >= 6 ? null : "كلمة المرور قصيرة",
      decoration: _buildInputDecoration("كلمة المرور", Icons.lock_outline, suffixIcon: IconButton(
        icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off, color: primaryColor),
        onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
      )),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData prefixIcon, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: primaryColor),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Colors.black45, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }

  Widget _buildResetPasswordButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: _isResetLoading ? null : resetPassword,
        child: _isResetLoading
            ? SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))
            : const Text("هل نسيت كلمة المرور؟", style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
      onPressed: _isLoading ? null : signIn,
      child: _isLoading
          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : const Text("تسجيل الدخول", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSignUpLink() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SignUpScreen())),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Colors.black),
          children: [
            const TextSpan(text: "لا تملك حساباً؟ "),
            TextSpan(text: "إنشاء حساب", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
