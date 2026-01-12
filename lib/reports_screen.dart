import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final Color primaryColor = const Color(0xFF6B8068);
  final Color cardBgColor = Colors.white;

  double todaySales = 0.0;
  double todayProfit = 0.0;
  double totalDebts = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDailyReport();
  }

  Future<void> _fetchDailyReport() async {
    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final invoicesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('invoices')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      double salesSum = 0.0;
      double profitSum = 0.0;

      for (var doc in invoicesSnapshot.docs) {
        var data = doc.data();
        
        salesSum += (data['paidCash'] ?? 0.0).toDouble();

        profitSum += (data['totalNetProfit'] ?? 0.0).toDouble();
      }

      // --- حساب مجموع الديون ---
      final customersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('customers')
          .get();

      double debtsSum = 0.0;
      for (var doc in customersSnapshot.docs) {
        debtsSum += (doc.data()['totalDebt'] ?? 0.0).toDouble();
      }

      if (mounted) {
        setState(() {
          todaySales = salesSum;
          todayProfit = profitSum;
          totalDebts = debtsSum;
          isLoading = false;
        });
      }

    } catch (e) {
      print("Error fetching reports: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf1f2ed),
      appBar: AppBar(
        title: const Text("الاستعلامات والتقارير", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchDailyReport,
          )
        ],
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "ملخص اليوم",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 15),
                
                _buildReportCard(
                  title: "إجمالي مبيعات اليوم",
                  amount: todaySales,
                  icon: Icons.point_of_sale,
                  color: Colors.blue.shade700,
                ),
                
                const SizedBox(height: 15),

                _buildReportCard(
                  title: "صافي ربح اليوم",
                  amount: todayProfit,
                  icon: Icons.trending_up,
                  color: Colors.green.shade700,
                  isProfit: true,
                ),

                const SizedBox(height: 30),
                Divider(color: Colors.black.withOpacity(0.1), thickness: 1),
                const SizedBox(height: 15),

                const Text(
                  "الذمم المالية",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 15),

                // كرت الديون
                _buildReportCard(
                  title: "مجموع الديون",
                  amount: totalDebts,
                  icon: Icons.account_balance_wallet,
                  color: Colors.orange.shade800,
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    bool isProfit = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                "${amount.toStringAsFixed(2)} د.أ",
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
        ],
      ),
    );
  }
}