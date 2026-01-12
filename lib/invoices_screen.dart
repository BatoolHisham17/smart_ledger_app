import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  _InvoicesScreenState createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final Color primaryColor = const Color(0xFF6B8068);
  final Color returnColor = const Color(0xFFD32F2F);
  final Color backgroundColor = const Color(0xFFf1f2ed);
  
  late CollectionReference invoicesRef;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    invoicesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('invoices');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("سجل الفواتير", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: invoicesRef.orderBy('date', descending: true).snapshots(),
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
                  Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text("لا يوجد فواتير مسجلة", style: TextStyle(color: Colors.grey, fontSize: 16)),
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
                return _buildInvoiceCard(doc.id, data);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceCard(String docId, Map<String, dynamic> data) {
    bool isDebt = data['isDebt'] ?? false;
    String? customerId = data['customerId'];
    
    String typeLabel;
    Color statusColor;
    IconData statusIcon;

    if (isDebt) {
      typeLabel = "فاتورة دين";
      statusColor = Colors.orange[800]!;
      statusIcon = Icons.money_off;
    } else if (customerId != null) {
      typeLabel = "سداد دفعة";
      statusColor = Colors.green;
      statusIcon = Icons.attach_money;
    } else {
      typeLabel = "بيع نقد";
      statusColor = primaryColor;
      statusIcon = Icons.payments;
    }

    double total = (data['totalAmount'] ?? 0).toDouble();
    String customerName = data['customerName'] ?? "زبون عام";

    Timestamp? timestamp = data['date'];
    String dateStr = "--/--/----";
    if (timestamp != null) {
      DateTime date = timestamp.toDate();
      dateStr = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15),side: BorderSide(color: primaryColor.withOpacity(0.1), width: .5)),
      color: Colors.white70,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),        
        onTap: () { 
          Navigator.push(context,
            MaterialPageRoute(builder: (context) => InvoiceDetailsScreen(
                invoiceId: docId, 
                data: data, 
                typeLabel: typeLabel, 
                themeColor: statusColor
              ),
            ),
          );
        },
        leading: CircleAvatar(radius: 25, backgroundColor: statusColor.withOpacity(0.1), child: Icon(statusIcon, color: statusColor)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text((isDebt || typeLabel == "سداد دفعة") ? customerName : "فاتورة نقدية", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(typeLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        trailing: Text("${total.abs().toStringAsFixed(2)} د.أ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor)),
      ),
    );
  }
}


class InvoiceDetailsScreen extends StatelessWidget {
  final String invoiceId;
  final Map<String, dynamic> data;
  final String typeLabel;
  final Color themeColor;

  const InvoiceDetailsScreen({
    super.key, 
    required this.invoiceId, 
    required this.data,
    required this.typeLabel,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color returnColor = const Color(0xFFD32F2F);
    
    double total = (data['totalAmount'] ?? 0).toDouble();
    double paidCash = (data['paidCash'] ?? 0).toDouble();
    double remainingDebt = (data['remainingDebt'] ?? 0).toDouble();
    double returnAmount = (data['totalReturnAmount'] ?? 0).toDouble();

    
    String customerName = data['customerName'] ?? "غير معروف";
    String? customerId = data['customerId'];
    List items = data['items'] ?? [];
    
    Timestamp? timestamp = data['date'];
    String fullDate = "--/--/----";
    if (timestamp != null) {
      DateTime d = timestamp.toDate();
      fullDate = "${d.year}-${d.month}-${d.day}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
    }

    bool isPaymentTransaction = typeLabel == "سداد دفعة";

    return Scaffold(
      backgroundColor: const Color(0xFFf1f2ed),
      appBar: AppBar(
        title: Text(typeLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: themeColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("#${invoiceId.substring(0, 8)}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text(fullDate, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(isPaymentTransaction ? "المبلغ المستلم" : "قيمة الفاتورة", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  Text("${total.toStringAsFixed(2)} د.أ", style: TextStyle(color: themeColor, fontSize: 36, fontWeight: FontWeight.bold)),
                  if (returnAmount > 0) 
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(5)),
                      child: Text("تتضمن مرتجعات بقيمة: ${returnAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            if (customerId != null)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: themeColor.withOpacity(0.1),width: 1),
                ),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: themeColor.withOpacity(0.1), child: Icon(Icons.person, color: themeColor)),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("الزبون", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 15),

            if (!isPaymentTransaction) ...[
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: themeColor.withOpacity(0.1),width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("الأصناف", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Divider(color: Colors.black.withOpacity(0.1), thickness: 1),
                    if (items.isEmpty) 
                       const Center(child: Text("لا يوجد أصناف", style: TextStyle(color: Colors.grey))),
                    
                    ...items.map((item) {
                      bool itemIsReturn = item['isReturn'] ?? false;
                      Color itemColor = itemIsReturn ? returnColor : Colors.black;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(item['name'] ?? "منتج", style: TextStyle(fontWeight: FontWeight.bold, color: itemColor)),
                                    if (itemIsReturn)
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: returnColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text("مرتجع", style: TextStyle(color: returnColor, fontSize: 10, fontWeight: FontWeight.bold))
                                      ),
                                  ],
                                ),
                                Text("${item['qty']} × ${item['price']} د.أ", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                            Text("${item['total'].toStringAsFixed(2)} د.أ", style: TextStyle(fontWeight: FontWeight.bold, color: itemColor)),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 15),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: themeColor.withOpacity(0.1),width: 1),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 50, color: Colors.green),
                    const SizedBox(height: 10),
                    const Text("عملية سداد ذمم ناجحة", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 5),
                    Text("تم خصم المبلغ من رصيد الزبون", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              const SizedBox(height: 15),
            ],

            // 4. التفاصيل المالية (للفواتير فقط، أو للدفعات إذا أردت التأكيد)
            if (!isPaymentTransaction && typeLabel == "فاتورة دين")
              Container(
                padding: const EdgeInsets.all(15),
                 decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: themeColor.withOpacity(0.1),width: 1),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow("المدفوع مقدماً", paidCash, Colors.green),
                    Divider(color: Colors.black.withOpacity(0.1), thickness: 1),
                    _buildSummaryRow("المتبقي ذمم", remainingDebt, Colors.red),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text("${amount.toStringAsFixed(2)} د.أ", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}