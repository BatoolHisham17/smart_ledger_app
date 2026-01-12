import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'invoices_screen.dart'; 

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  _CustomersScreenState createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final Color primaryColor = const Color(0xFF6B8068);
  final Color backgroundColor = const Color(0xFFf1f2ed);
  
  late CollectionReference customersRef;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? ''; 
    
    customersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('customers');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("إدارة الزبائن", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
          TextEditingController phoneCtrl = TextEditingController();
          
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => StatefulBuilder(
               builder: (context, setState) {
                return AlertDialog(
                  backgroundColor: backgroundColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),),
                  title: Text("إضافة زبون جديد", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, ),),
                  content: SingleChildScrollView(
                    child: Form(
                       key: _formKey,

                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTextField(nameCtrl, "الاسم الكامل", Icons.person_outline),
                            const SizedBox(height: 10),
                            _buildTextField(phoneCtrl, "رقم الهاتف", Icons.phone_android, isNumber: true),
                         ],
                        ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
                    ),
                    _isDialogLoading ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor),
                     ),
                    )
                    : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isDialogLoading = true);
                          try {
                            final Map<String, dynamic> data = {
                              'fullName': nameCtrl.text.trim(),
                              'phoneNumber': phoneCtrl.text.trim(),
                              'createdAt': FieldValue.serverTimestamp(),
                              'totalDebt': 0.0,
                            };
                            
                            await customersRef.add(data);

                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: primaryColor,
                                  content: Row( 
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white, size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text("تمت إضافة الزبون بنجاح", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("خطأ: $e")),
                            );
                          }
                        }
                      },
                      child: const Text(
                        "إضافة",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  },
  icon: const Icon(Icons.person_add, color: Colors.white),
  label: const Text("إضافة زبون",style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
),

      body: StreamBuilder<QuerySnapshot>(
        stream: customersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor));
            
          }
          if (snapshot.hasError) {
            return Center(child: Text("حدث خطأ: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text("لا يوجد زبائن، أضف زبوناً جديداً", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildCustomerCard(doc.id, data);
                
              },
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildTextField(TextEditingController ctrl, String labelText, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      validator: (val) => (val == null || val.isEmpty) ? "مطلوب" : (isNumber && !RegExp(r'^07\d{8}$').hasMatch(val)) ? "رقم الهاتف غير صالح" : null,
      decoration: InputDecoration(
        label: FittedBox(fit: BoxFit.scaleDown, child: Text(labelText)),
        labelStyle: TextStyle(color: primaryColor.withOpacity(0.7), fontSize: 13),
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2), borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      ),
    );
  }

  Widget _buildCustomerCard(String docId, Map<String, dynamic> data) {
    String name = data['fullName'] ?? 'زبون بدون اسم';
    String phone = data['phoneNumber'] ?? 'لا يوجد رقم';
    double debt = (data['totalDebt'] ?? 0).toDouble();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15),side: BorderSide(color: primaryColor.withOpacity(0.1), width: 1)),
      color: Colors.white70,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        leading: CircleAvatar(radius: 25, backgroundColor: primaryColor.withOpacity(0.1), child: Icon(Icons.person, color: primaryColor)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(phone, style: TextStyle(color: Colors.grey[600])),
        onTap: () {
          Navigator.push(context,
          MaterialPageRoute(builder: (context) => CustomerDetailsScreen(customerId: docId, customerData: data)),
          );
        },

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text("الدين الحالي", style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text(
                  "${debt.toStringAsFixed(2)} د.أ",
                  style: TextStyle(fontWeight: FontWeight.bold, color: debt > 0 ? Colors.red : Colors.green, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(width: 5),
            PopupMenuButton(
              elevation: 1,
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              color: backgroundColor,
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.green), SizedBox(width: 8), Text("تعديل")]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text("حذف")]),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  final _formKey = GlobalKey<FormState>();
                  bool _isDialogLoading = false;
                  
                  TextEditingController nameCtrl = TextEditingController(text: data['fullName']);
                  TextEditingController phoneCtrl = TextEditingController(text: data['phoneNumber']);
                  
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          backgroundColor: backgroundColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text("تعديل بيانات الزبون", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                          content: SingleChildScrollView(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                    controller: nameCtrl,
                                    textAlign: TextAlign.right,
                                    validator: (val) => (val == null || val.isEmpty) ? "مطلوب" : null,
                                    decoration: InputDecoration(
                                      label: FittedBox(fit: BoxFit.scaleDown, child: Text("الاسم الكامل")),
                                      labelStyle: TextStyle(color: primaryColor.withOpacity(0.7), fontSize: 13),
                                      prefixIcon: Icon(Icons.person_outline,color: primaryColor),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),borderSide: BorderSide.none),
                                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 1),borderRadius: BorderRadius.circular(10))
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  TextFormField(
                                    controller: phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    validator: (val) => (val == null || val.isEmpty) ? "مطلوب" : (!RegExp(r'^07\d{8}$').hasMatch(val)) ? "رقم الهاتف غير صالح" : null,
                                    decoration: InputDecoration(
                                      label: FittedBox(fit: BoxFit.scaleDown, child: Text("رقم الهاتف")),
                                      labelStyle: TextStyle(color: primaryColor.withOpacity(0.7), fontSize: 13),
                                      prefixIcon: Icon(Icons.person_outline,color: primaryColor),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),borderSide: BorderSide.none),
                                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 1),borderRadius: BorderRadius.circular(10))
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("إلغاء",style: TextStyle(color: Colors.grey))),
                              _isDialogLoading
                              ? Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor)),
                              )
                              : ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() => _isDialogLoading = true);
                                    try {
                                      await customersRef.doc(docId).update({
                                        'fullName': nameCtrl.text.trim(),
                                        'phoneNumber': phoneCtrl.text.trim(),
                                      });
                                      
                                      if (context.mounted) {
                                        Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: primaryColor,
                                  content: Row( 
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white, size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text("تم التعديل", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                      ),
                                   ],
                                  ),
                                   elevation: 0,
                                   duration: Duration(seconds: 1),
                                ),
                              );                                      }
                                    } catch (e) {
                                       setState(() => _isDialogLoading = false);
                                    }
                                  }
                                },
                                child: const Text("حفظ",style: TextStyle(color: Colors.white)),
                             ),
                          ],
                        );
                      },
                    ),
                  );
                }
                else if (value == 'delete') {
                  showDialog(
                    context: context,
                     builder: (ctx) => AlertDialog(
                      backgroundColor: backgroundColor,
                      title: Row(
                        children: [
                           Icon(Icons.warning, color: Colors.red),
                           SizedBox(width: 10),
                           Text("تأكيد الحذف",style: TextStyle(color: primaryColor)),
                        ],
                      ),
                      content:
                      const Text("هل أنت متأكد؟ سيتم حذف الزبون وسجله بالكامل."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), 
                        child: const Text("إلغاء",style: TextStyle(color: Colors.grey))),
                        ElevatedButton(
                          style:ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await customersRef.doc(docId).delete();
                            if (context.mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: primaryColor,
                                  content: Row( 
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white, size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text("تم الحذف", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                      ),
                                   ],
                                  ),
                                   elevation: 0,
                                   duration: Duration(seconds: 1),
                                ),
                              );
                            };
                          },
                          child: const Text("حذف",style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }
             },
            ),
          ],
        ),
      ),
    );
  }  
}


class CustomerDetailsScreen extends StatefulWidget {
  final String customerId;
  final Map<String, dynamic> customerData;

  const CustomerDetailsScreen({super.key, required this.customerId, required this.customerData});

  @override
  _CustomerDetailsScreenState createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  final Color primaryColor = const Color(0xFF6B8068);
  final Color backgroundColor = const Color(0xFFf1f2ed);
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    final Stream<DocumentSnapshot> customerStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('customers')
        .doc(widget.customerId)
        .snapshots();

    final Query invoicesQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('invoices')
        .where('customerId', isEqualTo: widget.customerId);

    return StreamBuilder<DocumentSnapshot>(
      stream: customerStream,
      builder: (context, custSnapshot) {
        if (!custSnapshot.hasData) return  Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor)));
        
        if (!custSnapshot.data!.exists) return const Scaffold(body: Center(child: Text("الزبون غير موجود")));

        var currentData = custSnapshot.data!.data() as Map<String, dynamic>;
        double currentDebt = (currentData['totalDebt'] ?? 0).toDouble();

        return Scaffold(
          backgroundColor: const Color(0xFFf1f2ed),
          appBar: AppBar(
            //title: Text(currentData['fullName'] ?? "الزبون", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            //centerTitle: true,
            backgroundColor: primaryColor,
            elevation: 0,
          ),
          floatingActionButton: currentDebt > 0 
            ? FloatingActionButton.extended(
                elevation: 1,
                backgroundColor: Colors.orange[800],
                icon: const Icon(Icons.attach_money, color: Colors.white),
                label: const Text("سداد دفعة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () {
                  final TextEditingController amountController = TextEditingController();
                  final GlobalKey<FormState> _payKey = GlobalKey<FormState>();
                  bool _isPaying = false;
                  
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => StatefulBuilder(builder: (context, setStateDialog) {
                      return AlertDialog(
                        backgroundColor: backgroundColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text("تسديد دفعة", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                        content: SingleChildScrollView(
                          child: Form(key: _payKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("الدين الحالي: ${currentDebt.toStringAsFixed(2)} د.أ",style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 15),
                              TextFormField(
                                controller: amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return "أدخل المبلغ";
                                  double? amount = double.tryParse(val);
                                  if (amount == null || amount <= 0)
                                   return "مبلغ غير صحيح";
                                  if (amount > currentDebt)
                                   return "المبلغ أكبر من الدين!";
                                   return null;
                                },                                
                                decoration: InputDecoration(
                                  label: FittedBox(fit: BoxFit.scaleDown, child: Text("المبلغ المدفوع")),
                                  labelStyle: TextStyle(color: primaryColor.withOpacity(0.7), fontSize: 13),
                                  prefixIcon: Icon(Icons.attach_money, color: primaryColor, size: 20),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 1)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 2)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                ),
                              ),
                            ],
                          ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                             child: const Text("إلغاء", style: TextStyle(color: Colors.grey))),
                             _isPaying 
                             ?  Padding(
                               padding: EdgeInsets.all(8.0),
                               child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor))
                             : ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                              onPressed: () async {
  if (_payKey.currentState!.validate()) {
    setStateDialog(() => _isPaying = true);
    try {
      double amountPaid = double.parse(amountController.text);
      final user = FirebaseAuth.instance.currentUser;
      
      double currentPendingProfit = widget.customerData['pendingProfit']?.toDouble() ?? 0.0;
      
      double realizedProfitNow = 0.0;
      
      if (amountPaid >= currentPendingProfit) {
        realizedProfitNow = currentPendingProfit;
      } else {
        realizedProfitNow = amountPaid;
      }

      await FirebaseFirestore.instance
      .collection('users')
      .doc(user!.uid)
      .collection('customers')
      .doc(widget.customerId)
      .update({
        'totalDebt': FieldValue.increment(-amountPaid),
        
        'pendingProfit': FieldValue.increment(-realizedProfitNow),
      });

      
      await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('invoices')
      .add({
       "customerId": widget.customerId,
       "customerName": widget.customerData['fullName'],
       "date": FieldValue.serverTimestamp(),
       "isDebt": false,
       "isReturn": false,
       "paidCash": amountPaid,
       "remainingDebt": 0.0,
       "totalAmount": amountPaid,
       "totalReturnAmount": 0.0,
       
       "totalNetProfit": realizedProfitNow, 
       
       "items": [{
          "productId": null,
          "name": 'سداد دفعة نقدية',
          "price": amountPaid,
          "costPrice": 0.0,
          "qty": 1,
          "total": amountPaid,
          "isReturn": false,
          "netProfit": realizedProfitNow, 
          "totalReturns": 0.0
        }],
      });
      
      if (mounted) {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: primaryColor,
            content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 10), Text("تم السداد وتسجيل الربح")]),
          ),
        );
      }
    } catch (e) {
      setStateDialog(() => _isPaying = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
  }
},
                              child: const Text("تأكيد الدفع",style: TextStyle(color: Colors.white)),
                         )],
                       );
                    },
                  ));
                },
              ): null,
              
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(radius: 35, backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Color(0xFF6B8068))),
                    const SizedBox(height: 10),
                    Text(currentData['fullName'] ?? "",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(currentData['phoneNumber'] ?? "", style: const TextStyle(fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
                      child: Column(
                        children: [
                          const Text("إجمالي الدين المستحق", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text("${currentDebt.toStringAsFixed(2)} د.أ",style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text("سجل العمليات", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                ),
              ),
              
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: invoicesQuery.snapshots(), 
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            const Text("لا يوجد سجلات لهذا الزبون", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }
                    
                    final docs = snapshot.data!.docs;
                    docs.sort((a, b) {
                      Timestamp t1 = (a.data() as Map<String, dynamic>)['date'] ?? Timestamp.now();
                      Timestamp t2 = (b.data() as Map<String, dynamic>)['date'] ?? Timestamp.now();
                      return t2.compareTo(t1);
                    });

                    return SafeArea(
                      child: ListView.builder(
                      padding: const EdgeInsets.all(15),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var doc = docs[index];
                        var data = doc.data() as Map<String, dynamic>;
                        
                        Timestamp? date = data['date'];
                        String dateStr = date != null 
                            ? "${date.toDate().day}/${date.toDate().month}/${date.toDate().year}" 
                            : "--/--/----";
                        
                        double total = (data['totalAmount'] ?? 0).toDouble();
                        bool isDebt = data['isDebt'] ?? false;
                        bool isPayment = !isDebt; 
                        List items = data['items'] ?? [];
                        if (items.isNotEmpty && items[0]['name'] == 'سداد دفعة نقدية') {
                           isPayment = true;
                        }

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15),side: BorderSide(color: primaryColor.withOpacity(0.1), width: .5)),
                          color: Colors.white70,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            leading: Icon(
                              isPayment ? Icons.payment : Icons.receipt_long,
                              color: isPayment ? Colors.green : primaryColor
                            ),
                            title: Text(
                              isPayment ? "سداد دفعة" : "فاتورة مشتريات", 
                              style: const TextStyle(fontWeight: FontWeight.bold)
                            ),
                            subtitle: Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            trailing: Text(
                              "${isPayment ? "-" : "+"}${total.toStringAsFixed(2)} د.أ",
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold, 
                                color: isPayment ? Colors.green : Colors.red
                              ),
                            ),
                            onTap: () {
                              String typeLabel = isPayment ? "سداد دفعة" : "فاتورة مشتريات";
                              Color themeColor = isPayment ? Colors.green : primaryColor;
                              
                              Navigator.push(context,
                               MaterialPageRoute(
                                 builder: (context) => InvoiceDetailsScreen(invoiceId: doc.id, data: data, typeLabel: typeLabel, themeColor: themeColor),
                               ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}