import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Form key
  final _formKey = GlobalKey<FormState>();

  // Colors
  final Color primaryColor = const Color(0xFF6B8068);

  // UI State
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  // -------------------------------
  // Authentication Methods
  // -------------------------------

  Future<void> signUp() async {
    if (!_formKey.currentState!.validate()) return;

    _setLoading(true);
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      )
      .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw FirebaseAuthException(
            code: 'network-request-failed',
         );

       },
      );

if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(nameController.text.trim());
      
        try {
        await FirebaseFirestore.instance
            .collection('users') 
            .doc(userCredential.user!.uid) 
            .set({
              'uid': userCredential.user!.uid,
              'name': nameController.text.trim(),
              'email': emailController.text.trim(),
              'storeName': "متجر ${nameController.text.trim()}",
              'createdAt': FieldValue.serverTimestamp(),
              'role': 'owner',
            });
        } catch (dbError) {
          throw "مشكلة في قاعدة البيانات: $dbError";
        }
      }

      _showSnackBar("✅ تم إنشاء الحساب بنجاح! يرجى تسجيل الدخول.");
      if (mounted) Navigator.of(context).pop();

    } on FirebaseAuthException catch (e) {
      _showErrorDialog("فشل التسجيل", _translateAuthError(e.code));
    } finally {
      _setLoading(false);
    }
  }

  String _translateAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'هذا البريد مسجل مسبقاً.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة.';
      case 'invalid-email':
        return 'بريد إلكتروني غير صحيح.';
      case 'network-request-failed':
       return 'لا يوجد اتصال بالإنترنت أو الاتصال بطيء جداً.';
      default:
        return 'حدث خطأ غير متوقع.';
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: Text(message),
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: primaryColor, content: Text(message)));
  }

  void _setLoading(bool value) {
    if (!mounted) return;
    setState(() => _isLoading = value);
  }

  // -------------------------------
  // UI
  // -------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf1f2ed),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 50),
                _buildLogo(),
                const SizedBox(height: 40),
                _buildFormFields(),
                const SizedBox(height: 50),
                _buildSignInLink(),
              ],
            ),
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
          errorBuilder: (_, __, ___) => Icon(Icons.person_add, size: 60, color: primaryColor),
        ),
        const SizedBox(height: 10),
        Image.asset(
          'assets/images/logo.png',
          width: 70,
          height: 14,
          errorBuilder: (_, __, ___) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return FractionallySizedBox(
      widthFactor: 0.85,
      child: Column(
        children: [
          _buildTitle("إنشاء حساب جديد"),
          const SizedBox(height: 15),
          _buildTextField(nameController, "اسم المتجر", Icons.person_outline),
          const SizedBox(height: 15),
          _buildTextField(emailController, "البريد الإلكتروني", Icons.email_outlined, isEmail: true),
          const SizedBox(height: 15),
          _buildPasswordField(passwordController, "كلمة المرور", _passwordVisible, () => setState(() => _passwordVisible = !_passwordVisible)),
          const SizedBox(height: 15),
          _buildPasswordField(confirmPasswordController, "تأكيد كلمة المرور", _confirmPasswordVisible, () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible), isConfirm: true),
          const SizedBox(height: 30),
          _buildSignUpButton(),
        ],
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (val) {
        if (val == null || val.trim().isEmpty) return "مطلوب";
        if (isEmail) {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(val.trim())) return "الرجاء إدخال بريد إلكتروني صالح";
        }
        return null;
      },
      decoration: _inputDecoration(hint, icon),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String hint, bool isVisible, VoidCallback onToggle, {bool isConfirm = false}) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (val) {
        if (val == null || val.length < 6) return "كلمة المرور قصيرة";
        if (isConfirm && val != passwordController.text) return "كلمتا المرور غير متطابقتين";
        return null;
      },
      decoration: _inputDecoration(hint, Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: primaryColor),
          onPressed: onToggle,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryColor),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: Colors.black45, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide(color: primaryColor, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide(color: primaryColor, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide(color: primaryColor, width: 1.5)),
    );
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
      onPressed: _isLoading ? null : signUp,
      child: _isLoading
          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : const Text("إنشاء حساب", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSignInLink() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Colors.black),
          children: [
            const TextSpan(text: "لديك حساب بالفعل؟ "),
            TextSpan(text: "تسجيل الدخول", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
