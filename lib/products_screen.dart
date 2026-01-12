import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final Color primaryColor = const Color(0xFF6B8068);
  final Color backgroundColor = const Color(0xFFf1f2ed);
  
  late CollectionReference productsRef;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? ''; 
    
    productsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('products');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("المخزون والمنتجات", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        elevation: 0,
        onPressed: () {
          final _formKey = GlobalKey<FormState>();
          bool _isDialogLoading = false;
          
          TextEditingController nameCtrl = TextEditingController();
          TextEditingController sellCtrl = TextEditingController();
          TextEditingController costCtrl = TextEditingController();
          TextEditingController qtyCtrl = TextEditingController();
          TextEditingController limitCtrl = TextEditingController(text: '5');

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => StatefulBuilder(
              builder: (context, setState) {
                Widget buildLocalField(TextEditingController ctrl, String labelText, IconData icon, {bool isNumber = false}) {
                  return TextFormField(
                    controller: ctrl,
                    keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                    validator: (val) => (val == null || val.isEmpty) ? "مطلوب" : null,
                    decoration: InputDecoration(
                      label: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(labelText)),
                      labelStyle: TextStyle(color: primaryColor.withOpacity(0.7), fontSize: 13),
                      floatingLabelStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(icon, color: primaryColor, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2), borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    ),
                  );
                }

                return AlertDialog(
                  backgroundColor: backgroundColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text("إضافة منتج جديد", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  content: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildLocalField(nameCtrl, "اسم المنتج", Icons.shopping_bag),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(child: buildLocalField(sellCtrl, "سعر البيع", Icons.attach_money, isNumber: true)),
                              const SizedBox(width: 10),
                              Expanded(child: buildLocalField(costCtrl, "سعر الشراء", Icons.money_off, isNumber: true)),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(child: buildLocalField(qtyCtrl, "الكمية", Icons.layers_outlined, isNumber: true)),
                              const SizedBox(width: 10),
                              Expanded(child: buildLocalField(limitCtrl, "الحد الأدنى", Icons.warning_amber, isNumber: true)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء", style: TextStyle(color: Colors.grey))),
                    _isDialogLoading 
                      ? Padding(padding: const EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor)))
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isDialogLoading = true); 
                              try {
                                final data = {
                                  'name': nameCtrl.text.trim(),
                                  'sellPrice': double.tryParse(sellCtrl.text) ?? 0.0,
                                  'costPrice': double.tryParse(costCtrl.text) ?? 0.0,
                                  'quantity': int.tryParse(qtyCtrl.text) ?? 0,
                                  'limit': int.tryParse(limitCtrl.text) ?? 5,
                                  'createdAt': FieldValue.serverTimestamp(),
                                };
                                
                                await productsRef.add(data);
                                
                                if (mounted) {
                                  Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: primaryColor,
                                  content: Row( 
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white, size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text("تمت الإضافة بنجاح", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                      ),
                                   ],
                                  ),
                                   elevation: 0,
                                   duration: Duration(seconds: 1),
                                ),
                              );
                                }
                              } catch (e) {
                                setState(() => _isDialogLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e"), backgroundColor: primaryColor, behavior: SnackBarBehavior.floating));
                              }
                            }
                          },
                          child: const Text("إضافة", style: TextStyle(color: Colors.white)),
                        ),
                  ],
                );
              }
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("إضافة منتج", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: productsRef.snapshots(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text("حدث خطأ تقني:", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text("المخزون فارغ، ابدأ بإضافة المنتجات", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          docs.sort((a, b) {
            Timestamp t1 = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp? ?? Timestamp.fromMicrosecondsSinceEpoch(0);
            Timestamp t2 = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp? ?? Timestamp.fromMicrosecondsSinceEpoch(0);
            return t2.compareTo(t1);
          });
          
          return SafeArea(
            child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              String docId = doc.id;
              
              String name = data['name'] ?? 'بدون اسم';
              double sellPrice = (data['sellPrice'] ?? 0).toDouble();
              double costPrice = (data['costPrice'] ?? 0).toDouble();
              int quantity = (data['quantity'] ?? 0).toInt();
              int limit = (data['limit'] ?? 5).toInt();
              bool isLowStock = quantity <= limit;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: isLowStock ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: isLowStock ? Colors.red.shade100 : primaryColor.withOpacity(0.1),
                    child: Icon(Icons.inventory, color: isLowStock ? Colors.red : primaryColor),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 15,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text("بيع: $sellPrice د.أ", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 13)),
                        Text("شراء: $costPrice د.أ", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.layers_outlined, size: 16, color: isLowStock ? Colors.red : Colors.black54),
                            const SizedBox(width: 4),
                            Text("الكمية: $quantity", style: TextStyle(fontWeight: FontWeight.bold, color: isLowStock ? Colors.red : Colors.black87, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: PopupMenuButton(
                    color: Colors.white,
                    elevation: 2,
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'edit') {
                        final _formKeyEdit = GlobalKey<FormState>();
                        bool _isDialogLoadingEdit = false;
                        
                        TextEditingController nameCtrl = TextEditingController(text: data['name']);
                        TextEditingController sellCtrl = TextEditingController(text: data['sellPrice']?.toString());
                        TextEditingController costCtrl = TextEditingController(text: data['costPrice']?.toString());
                        TextEditingController qtyCtrl = TextEditingController(text: data['quantity']?.toString());
                        TextEditingController limitCtrl = TextEditingController(text: data['limit']?.toString() ?? '5');

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => StatefulBuilder(
                            builder: (context, setStateEdit) {
                               Widget buildLocalField(TextEditingController ctrl, String labelText, IconData icon, {bool isNumber = false}) {
                                  return TextFormField(
                                    controller: ctrl,
                                    keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                                    textAlign: TextAlign.right,
                                    validator: (val) => (val == null || val.isEmpty) ? "مطلوب" : null,
                                    decoration: InputDecoration(
                                      label: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(labelText)),
                                      labelStyle: TextStyle(color: primaryColor.withOpacity(0.7), fontSize: 13),
                                      floatingLabelStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                                      prefixIcon: Icon(icon, color: primaryColor, size: 20),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2), borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                    ),
                                  );
                                }

                                return AlertDialog(
                                  backgroundColor: backgroundColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: Text("تعديل المنتج", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                  content: SingleChildScrollView(
                                    child: Form(
                                      key: _formKeyEdit,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          buildLocalField(nameCtrl, "اسم المنتج", Icons.shopping_bag),
                                          const SizedBox(height: 15),
                                          Row(
                                            children: [
                                              Expanded(child: buildLocalField(sellCtrl, "سعر البيع", Icons.attach_money, isNumber: true)),
                                              const SizedBox(width: 10),
                                              Expanded(child: buildLocalField(costCtrl, "سعر الشراء", Icons.money_off, isNumber: true)),
                                            ],
                                          ),
                                          const SizedBox(height: 15),
                                          Row(
                                            children: [
                                              Expanded(child: buildLocalField(qtyCtrl, "الكمية", Icons.layers_outlined, isNumber: true)),
                                              const SizedBox(width: 10),
                                              Expanded(child: buildLocalField(limitCtrl, "الحد الأدنى", Icons.warning_amber, isNumber: true)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء", style: TextStyle(color: Colors.grey))),
                                    _isDialogLoadingEdit 
                                      ? Padding(padding: const EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor)))
                                      : ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                          onPressed: () async {
                                            if (_formKeyEdit.currentState!.validate()) {
                                              setStateEdit(() => _isDialogLoadingEdit = true);
                                              try {
                                                final newData = {
                                                  'name': nameCtrl.text.trim(),
                                                  'sellPrice': double.tryParse(sellCtrl.text) ?? 0.0,
                                                  'costPrice': double.tryParse(costCtrl.text) ?? 0.0,
                                                  'quantity': int.tryParse(qtyCtrl.text) ?? 0,
                                                  'limit': int.tryParse(limitCtrl.text) ?? 5,
                                                };
                                                await productsRef.doc(docId).update(newData);
                                                if (mounted) {
                                                  Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: primaryColor,
                                  content: Row( 
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white, size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text("تم التعديل بنجاح", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                      ),
                                   ],
                                  ),
                                   elevation: 0,
                                   duration: Duration(seconds: 1),
                                ),
                              );                                                }
                                              } catch (e) {
                                                setStateEdit(() => _isDialogLoadingEdit = false);
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e"), backgroundColor: primaryColor, behavior: SnackBarBehavior.floating));
                                              }
                                            }
                                          },
                                          child: const Text("حفظ", style: TextStyle(color: Colors.white)),
                                        ),
                                  ],
                                );
                            }
                          ),
                        );

                      } else if (value == 'delete') {
                        showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: backgroundColor,
                            title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 10), Text("تأكيد الحذف")]),
                            content: const Text("هل أنت متأكد من حذف هذا المنتج؟ لا يمكن التراجع."),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء", style: TextStyle(color: Colors.grey))),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await productsRef.doc(docId).delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: primaryColor,
                                  content: Row( 
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white, size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text("تم حذف المنتج", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                      ),
                                   ],
                                  ),
                                   elevation: 0,
                                   duration: Duration(seconds: 1),
                                ),
                              );                                },
                                child: const Text("حذف", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.green), SizedBox(width: 8), Text("تعديل")])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text("حذف")])),
                    ],
                  ),
                ),
              );
            },
          ),
          );
        },
      ),
    );
  }
}