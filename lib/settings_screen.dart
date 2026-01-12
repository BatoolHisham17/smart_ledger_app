import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color primaryColor = Color(0xFF6B8068);
  static const Color backgroundColor = Color(0xFFf1f2ed);

  late TextEditingController _storeNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _phoneNumberController;
  
  String _userEmail = "";
  final _contactFormKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userEmail = user?.email ?? "لا يوجد بريد";
    _storeNameController = TextEditingController(text: user?.displayName ?? "متجر جديد");
    _ownerNameController = TextEditingController(text: "");
    _phoneNumberController = TextEditingController(text: "");
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }


  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    }
  }


  void _showSnackBar(String message) {
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: primaryColor, content: Text(message)));
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("الإعدادات", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle("هوية المتجر"),
                _buildSettingCard(
                  child: ListTile(
                    leading: _buildIconAvatar(Icons.storefront_outlined),
                    title: const Text("اسم المتجر", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(_storeNameController.text),
                    trailing: _buildEditIcon(),
                    onTap: _showEditNameDialog,
                  ),
                ),
                _buildSectionTitle("بيانات التواصل"),
                _buildSettingCard(
                  child: ListTile(
                    leading: _buildIconAvatar(Icons.perm_contact_calendar_outlined),
                    title: const Text("معلومات الاتصال", style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: _buildEditIcon(icon: Icons.arrow_forward_ios, size: 14),
                    onTap: _showEditContactInfoDialog,
                  ),
                ),
                _buildSectionTitle("الأمان والحساب"),
                _buildSettingCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.orange),
                        title: const Text("تسجيل الخروج"),
                        onTap: _logout,
                      ),
                      Divider(color: Colors.black.withOpacity(0.1), thickness: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.red),
                        title: const Text("حذف الحساب", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        subtitle: const Text("مسح كافة بياناتك نهائياً"),
                        onTap: _showDeleteConfirmation,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Center(
                  child: Text("Summ POS - إصدار 1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8, top: 20),
      child: Text(
        title,
        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildSettingCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildIconAvatar(IconData icon) {
    return CircleAvatar(
      backgroundColor: primaryColor.withOpacity(0.1),
      child: Icon(icon, color: primaryColor),
    );
  }

  Widget _buildEditIcon({IconData icon = Icons.edit, double size = 18}) {
    return Icon(icon, size: size, color: primaryColor.withOpacity(0.5));
  }


  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text("حذف الحساب نهائياً", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          "هل أنت متأكد؟ سيتم مسح كافة البيانات والفواتير والديون نهائياً ولا يمكن التراجع عن هذا الإجراء.",
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              _showReAuthDialog(); // الانتقال للتحقق الأمني
            },
            child: const Text("نعم، احذف الحساب", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReAuthDialog() {
    final emailAuth = TextEditingController(text: FirebaseAuth.instance.currentUser?.email);
    final passAuth = TextEditingController();
    final authKey = GlobalKey<FormState>();
    bool isAuthLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("تأكيد الهوية للحذف", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              content: isAuthLoading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: primaryColor),
                        const SizedBox(height: 15),
                        const Text("جاري التحقق وحذف البيانات..."),
                      ],
                    )
                  : Form(
                      key: authKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "لأغراض أمنية، يرجى تأكيد بريدك وكلمة المرور لإتمام الحذف.",
                            style: TextStyle(fontSize: 13, color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 15),
                          _buildDialogField(emailAuth, "البريد الإلكتروني", Icons.email, inputType: TextInputType.emailAddress),
                          const SizedBox(height: 10),
                          _buildDialogField(passAuth, "كلمة المرور", Icons.lock, isObscure: true),
                        ],
                      ),
                    ),
              actions: isAuthLoading
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () async {
                          if (authKey.currentState!.validate()) {
                            setStateDialog(() => isAuthLoading = true);
                            try {
                              AuthCredential credential = EmailAuthProvider.credential(
                                email: emailAuth.text.trim(),
                                password: passAuth.text.trim(),
                              );
                              await FirebaseAuth.instance.currentUser?.reauthenticateWithCredential(credential);
                              await FirebaseAuth.instance.currentUser?.delete();

                              if (mounted) {
                                Navigator.pop(context);
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (context) => LoginScreen()),
                                  (route) => false,
                                );
                              }
                            } on FirebaseAuthException catch (e) {
                              setStateDialog(() => isAuthLoading = false);
                              String errorMsg = "فشل التحقق";
                              if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
                                errorMsg = "كلمة المرور غير صحيحة";
                              }
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: primaryColor, content: Text(errorMsg)));
                            }
                          }
                        },
                        child: const Text("تأكيد وحذف نهائي", style: TextStyle(color: Colors.white)),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  void _showEditNameDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("تغيير اسم المتجر", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _storeNameController,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: "أدخل اسم المتجر الجديد",
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor.withOpacity(0.5))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("إلغاء", style: TextStyle(color: primaryColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              if (_storeNameController.text.trim().isNotEmpty) {
                try {
                  await FirebaseAuth.instance.currentUser?.updateDisplayName(_storeNameController.text.trim());
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() {});
                    _showSnackBar("تم تحديث اسم المتجر بنجاح");
                  }
                } catch (e) {
                  _showSnackBar("حدث خطأ أثناء التحديث");
                }
              }
            },
            child: const Text("حفظ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditContactInfoDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("معلومات الاتصال", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: _contactFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(
                  TextEditingController(text: _userEmail),
                  "البريد الإلكتروني",
                  Icons.email_outlined,
                  isReadOnly: true,
                ),
                const SizedBox(height: 15),
                _buildDialogField(_ownerNameController, "اسم المالك", Icons.person_outline, hint: "أدخل اسم المالك"),
                const SizedBox(height: 15),
                _buildPhoneField(_phoneNumberController, "رقم الهاتف", Icons.phone_iphone, hint: "مثال: 07XXXXXXXX"),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              if (_contactFormKey.currentState!.validate()) {
                Navigator.pop(context);
                setState(() {});
                _showSnackBar("تم حفظ بيانات التواصل");
              }
            },
            child: const Text("حفظ التغييرات", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField(TextEditingController controller, String label, IconData icon, {String? hint}) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      textAlign: TextAlign.right,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        if (value.length != 10 || !value.startsWith('07')) {
          return "رقم الهاتف غير صالح (يجب أن يبدأ بـ 07 ويكون 10 أرقام)";
        }
        return null;
      },
      decoration: _inputDecoration(label, icon, hint: hint, errorMaxLines: 2),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label, IconData icon,
      {TextInputType inputType = TextInputType.text, bool isReadOnly = false, String? hint, bool isObscure = false}) {
    return TextFormField(
      controller: controller,
      readOnly: isReadOnly,
      obscureText: isObscure,
      keyboardType: inputType,
      textAlign: TextAlign.right,
      style: TextStyle(color: isReadOnly ? Colors.grey : Colors.black),
      decoration: _inputDecoration(label, icon, hint: hint, isReadOnly: isReadOnly),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {String? hint, bool isReadOnly = false, int errorMaxLines = 1}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorMaxLines: errorMaxLines,
      prefixIcon: Icon(icon, color: primaryColor),
      labelStyle: TextStyle(color: primaryColor.withOpacity(0.7), fontSize: 13),
      filled: true,
      fillColor: isReadOnly ? Colors.grey[200] : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    );
  }
}