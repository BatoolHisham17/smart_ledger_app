import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart'; 
import 'providers/cart_provider.dart';   
import 'products_screen.dart';
import 'settings_screen.dart';
import 'customers_screen.dart';
import 'invoices_screen.dart';
import 'reports_screen.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';


class CartItem {
  String? id;
  String name;
  double price;
  double costPrice;
  int qty;
  double total;
  double netProfit;
  double totalReturns;
  bool isReturn;

  CartItem({
    this.id,
    required this.name,
    required this.price,
    required this.costPrice,
    required this.qty,
    required this.total,
    this.totalReturns = 0.0,
    this.netProfit = 0.0,
    this.isReturn = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': id,
      'name': name,
      'price': price,
      'costPrice': costPrice,
      'qty': qty,
      'total': total,
      'netProfit': netProfit,
      'totalReturns': totalReturns,
      'isReturn': isReturn,
    };
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  final Color primaryColor = const Color(0xFF6B8068);
  final Color secondaryColor = const Color(0xFFE8E9C9);
  final Color returnColor = const Color(0xFFD32F2F);

  final TextEditingController priceController = TextEditingController(text: "0.0");
  final TextEditingController cashPaidController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: "1");

  final FocusNode _cashFocusNode = FocusNode();
  FocusNode? _customerFocusNode;
  bool _isBottomSectionFocused = false;

  String? selectedProductId; 
  String selectedProductName = "";
  int currentStock = 0;
  double currentCostPrice = 0.0; 
  int quantity = 1;

  String? selectedCustomerId;
  String selectedCustomerName = "";

  bool isDebtMode = false;     
  bool isReturnMode = false;   
  bool isMaxStockReached = false;
  bool isPaymentError = false; 

  @override
  void initState() {
    super.initState();
    _cashFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _cashFocusNode.removeListener(_onFocusChange);
    _cashFocusNode.dispose();
    if (_customerFocusNode != null) {
       _customerFocusNode!.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  double get grandTotal {
    return Provider.of<CartProvider>(context, listen: false).grandTotal;
  }

  void _showSnackBar(String message, {IconData icon = Icons.info_outline, Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: color ?? primaryColor, 
        elevation: 0,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _incrementQuantity() {
    setState(() {
      if (isReturnMode) {
        quantity++;
      } else if (selectedProductId != null) {
        if (quantity < currentStock) {
          quantity++;
          isMaxStockReached = false;
        } else {
          isMaxStockReached = true;
        }
      } else {
        quantity++;
      }
      quantityController.text = quantity.toString();
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (quantity > 1) {
        quantity--;
        isMaxStockReached = false;
        quantityController.text = quantity.toString();
      }
    });
  }

  void _onQuantityChanged(String value) {
    int? newQuantity = int.tryParse(value);
    if (newQuantity != null && newQuantity > 0) {
      setState(() {
        quantity = newQuantity;
        if (!isReturnMode && selectedProductId != null) {
          if (quantity > currentStock) isMaxStockReached = true;
          else isMaxStockReached = false;
        } else {
           isMaxStockReached = false;
        }
      });
    }
  }

  void _onFocusChange() {
    final bool isCustomerFocused = _customerFocusNode?.hasFocus ?? false;
    final bool isCashFocused = _cashFocusNode.hasFocus;
    
    if (_isBottomSectionFocused != (isCustomerFocused || isCashFocused)) {
      setState(() {
        _isBottomSectionFocused = isCustomerFocused || isCashFocused;
      });
    }
  }

  void _addToCart() {
    if (selectedProductId == null || selectedProductName.isEmpty) {
      _showSnackBar("الرجاء البحث واختيار منتج من القائمة", icon: Icons.search_off, color: Colors.orange[800]);
      return;
    }

    double currentSellPrice = double.tryParse(priceController.text) ?? 0.0;
    
    if (!isReturnMode && quantity > currentStock) {
      _showSnackBar("الكمية غير متوفرة! المتوفر: $currentStock", icon: Icons.production_quantity_limits, color: Colors.red);
      return;
    }

    double finalTotal = (currentSellPrice * quantity);

    Provider.of<CartProvider>(context, listen: false).addToCart(CartItem(
      id: selectedProductId,
      name: selectedProductName,
      price: currentSellPrice,
      costPrice: currentCostPrice,
      qty: quantity,
      total: finalTotal,
      isReturn: isReturnMode,
    ));

    setState(() {
      selectedProductId = null;
      selectedProductName = "";
      currentStock = 0;
      currentCostPrice = 0.0; 
      quantity = 1;
      quantityController.text = "1";
      priceController.text = "0.0";
      isMaxStockReached = false;
    });
  }



Future<void> _processCheckout() async {
  final cartProvider = Provider.of<CartProvider>(context, listen: false);
  final cartItems = cartProvider.items;

  if (cartItems.isEmpty) return;
  
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  double cashPaidInput = double.tryParse(cashPaidController.text) ?? 0.0;
  double currentTotal = cartProvider.grandTotal; 
  
  if (isDebtMode) {
     if (selectedCustomerId == null) {
      _showSnackBar("يجب اختيار اسم الزبون لتسجيل الدين!", icon: Icons.person_add_disabled, color: Colors.orange[800]);
      return;
    }
    if (currentTotal > 0 && cashPaidInput > currentTotal) {
      _showSnackBar("المبلغ المدفوع أكبر من قيمة الفاتورة!", icon: Icons.money_off, color: Colors.red);
      return;
    }
  }

  double finalPaidCash = 0.0;
  double finalRemainingDebt = 0.0;

  if (!isDebtMode) {
    finalPaidCash = currentTotal;
    finalRemainingDebt = 0.0;
    selectedCustomerId = null;
    selectedCustomerName = "";
  } else {
    finalPaidCash = cashPaidInput;
    finalRemainingDebt = currentTotal - cashPaidInput;
  }

  double totalReturnAmount = 0.0;
  double sumPotentialProfit = 0.0;

  for (var item in cartItems) {
    if (item.total < 0) {
      totalReturnAmount += (item.total).abs();
    }
    if (!item.isReturn) {
        sumPotentialProfit += (item.price - item.costPrice) * item.qty;
     }
  }
  
  double dbTotalNetProfit = 0.0;  
  double profitToAddToPending = 0.0;

  if (!isDebtMode) {
     dbTotalNetProfit = sumPotentialProfit;
     profitToAddToPending = 0.0;
  } else {
     if (cashPaidInput >= sumPotentialProfit) {
       dbTotalNetProfit = sumPotentialProfit;
       profitToAddToPending = 0.0;
     } else {
       dbTotalNetProfit = cashPaidInput;
       profitToAddToPending = sumPotentialProfit - cashPaidInput;
     }
  }

  int invoiceSeq = await _getNextInvoiceNumber(user.uid);
  String invoiceNumberStr = invoiceSeq.toString().padLeft(4, '0');
  bool isOverallReturn = currentTotal < 0;

  WriteBatch batch = FirebaseFirestore.instance.batch();
  
  DocumentReference invoiceRef = FirebaseFirestore.instance
      .collection('users').doc(user.uid).collection('invoices').doc();

  for (var item in cartItems) {
    if (item.id == null) continue;
    DocumentReference prodRef = FirebaseFirestore.instance
        .collection('users').doc(user.uid).collection('products').doc(item.id);

    int change = item.isReturn ? item.qty : -item.qty; 
    batch.update(prodRef, {'quantity': FieldValue.increment(change)});
  }

  if (isDebtMode && selectedCustomerId != null) {
    DocumentReference custRef = FirebaseFirestore.instance
        .collection('users').doc(user.uid).collection('customers').doc(selectedCustomerId);
    
    batch.update(custRef, {
      'totalDebt': FieldValue.increment(finalRemainingDebt),
      'pendingProfit': FieldValue.increment(profitToAddToPending), 
      'lastTransactionDate': FieldValue.serverTimestamp(),
    });
  }

  Map<String, dynamic> invoiceData = {
    'invoiceNumber': invoiceNumberStr,
    'invoiceSeq': invoiceSeq,
    'date': FieldValue.serverTimestamp(),
    'totalAmount': currentTotal,
    'paidCash': finalPaidCash,
    'remainingDebt': finalRemainingDebt,
    'totalReturnAmount': totalReturnAmount,
    'totalNetProfit': dbTotalNetProfit, 
    'isReturn': isOverallReturn, 
    'isDebt': isDebtMode,
    'customerId': isDebtMode ? selectedCustomerId : null,
    'customerName': isDebtMode ? selectedCustomerName : null,
    'items': cartItems.map((e) => e.toMap()).toList(),
  };
  
  batch.set(invoiceRef, invoiceData);

  try {
    await batch.commit(); 
    cartProvider.clearCart(); 

    setState(() {
      cashPaidController.clear();
      selectedCustomerId = null;
      selectedCustomerName = "";
      isDebtMode = false;
      _isBottomSectionFocused = false;
    });
    FocusScope.of(context).unfocus();
    _showSnackBar("تم حفظ الفاتورة بنجاح", icon: Icons.check_circle, color: primaryColor);
  } catch (e) {
    _showSnackBar("حدث خطأ أثناء الحفظ: $e", icon: Icons.error, color: Colors.red);
  }
}

  Future<int> _getNextInvoiceNumber(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final counterRef = firestore.collection('users').doc(uid).collection('metadata').doc('invoiceCounter');

    return firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(counterRef);
      if (!snapshot.exists) {
        transaction.set(counterRef, {'current': 1});
        return 1;
      }
      int newCount = (snapshot.data() as Map<String, dynamic>)['current'] + 1;
      transaction.update(counterRef, {'current': newCount});
      return newCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? "مستخدم";
    final String email = user?.email ?? "";

    double cashInput = double.tryParse(cashPaidController.text) ?? 0.0;
    
    double currentGrandTotal = grandTotal; 
    
    if (isDebtMode && currentGrandTotal > 0 && cashInput > currentGrandTotal) isPaymentError = true;
    else isPaymentError = false;
    
    double debtDisplay = 0.0;
    if (isDebtMode) {
      debtDisplay = currentGrandTotal - cashInput;
    }

    Color activeColor = isReturnMode ? returnColor : primaryColor;
    bool isCredit = currentGrandTotal < 0; 

    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFf1f2ed),
      appBar: AppBar(
        title: Text(isReturnMode ? "⚠️ وضع المرتجعات" : "نقطة البيع", 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
        ),
        centerTitle: true,
        backgroundColor: activeColor,
        elevation: 0
      ),
      drawer: _buildDrawer(displayName, email),
      body: SafeArea(
        child: Column(
          children: [
             Expanded(
              flex: 3,
               child: ListView(
                padding: const EdgeInsets.all(12.0),
                  children: [
                    _buildInputCard(activeColor),
                    const SizedBox(height: 10),
                    _buildCartTable(), 
                  ],
                ),
               ),
              Padding(
                padding: EdgeInsets.only(bottom: _isBottomSectionFocused ? keyboardHeight : 0),
                child: _buildCheckoutSection(debtDisplay, isCredit, activeColor),
              ),
          ],
        ),
      ),
   );
  }

  Widget _buildInputCard(Color currentColor) {
    return _buildSectionCard(
      title: "إضافة صنف",
      icon: isReturnMode ? Icons.assignment_return : Icons.add_shopping_cart,
      iconColor: currentColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isReturnMode ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: currentColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Text("نوع العملية:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                AnimatedToggleSwitch<bool>.dual(
                  current: isReturnMode,
                  first: false,
                  second: true,
                  spacing: 40.0,
                  animationDuration: const Duration(milliseconds: 400),
                  style: ToggleStyle(
                    backgroundColor: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    borderColor: Colors.grey.shade50,
                  ),
                  onChanged: (val) {
                    setState(() {
                      isReturnMode = val;
                      isMaxStockReached = false;
                    });
                  },
                  iconBuilder: (value) => value
                      ? const Icon(Icons.assignment_return, color: Colors.white, size: 18)
                      : const Icon(Icons.shopping_cart, color: Colors.white, size: 18),
                  textBuilder: (value) => value
                      ? const Center(child: Text('مرتجع', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)))
                      : const Center(child: Text('بيع', style: TextStyle(color: Color(0xFF6B8068), fontWeight: FontWeight.bold, fontSize: 12))),
                  styleBuilder: (b) => ToggleStyle(
                    indicatorColor: b ? Colors.red : const Color(0xFF6B8068),
                    boxShadow: [BoxShadow(color: (b ? Colors.red : const Color(0xFF6B8068)).withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 2))],
                  ),
                  height: 40,
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          _buildAutocompleteSearch(currentColor),

          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: _inputStyle("السعر", Icons.attach_money, currentColor),
                ),
              ),
              const SizedBox(width: 10),
              
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: isMaxStockReached ? Colors.red : Colors.grey.shade300), 
                        borderRadius: BorderRadius.circular(10),
                        color: isMaxStockReached ? Colors.red.shade50 : Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(onPressed: _decrementQuantity, icon: const Icon(Icons.remove)),
                          SizedBox(
                            width: 50,
                            child: TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              onChanged: _onQuantityChanged,
                              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            onPressed: _incrementQuantity,
                            icon: Icon(Icons.add, color: isMaxStockReached ? Colors.grey : currentColor)
                          ),
                        ],
                      ),
                    ),
                    if (isMaxStockReached)
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Text("نفدت الكمية! (المتوفر: $currentStock)", style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isReturnMode ? returnColor : secondaryColor,
                elevation: 0
              ),
              onPressed: _addToCart,
              icon: Icon(isReturnMode ? Icons.keyboard_return : Icons.add, color: isReturnMode ? Colors.white : primaryColor),
              label: Text(
                isReturnMode ? "إرجاع للمخزون" : "أضف للفاتورة", 
                style: TextStyle(color: isReturnMode ? Colors.white : primaryColor, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutocompleteSearch(Color currentColor) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return TextField(decoration: _inputStyle("جاري التحميل...", Icons.search, Colors.grey).copyWith(enabled: false));
        List<QueryDocumentSnapshot> products = snapshot.data!.docs;
        return Autocomplete<QueryDocumentSnapshot>(
          displayStringForOption: (QueryDocumentSnapshot option) => option['name'],
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') return const Iterable<QueryDocumentSnapshot>.empty();
            return products.where((QueryDocumentSnapshot option) {
              return option['name'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (QueryDocumentSnapshot selection) {
            setState(() {
              selectedProductId = selection.id;
              selectedProductName = selection['name'];
              currentStock = (selection['quantity'] ?? 0).toInt();
              priceController.text = (selection['sellPrice'] ?? 0.0).toString();
              currentCostPrice = (selection['costPrice'] ?? 0.0).toDouble();

              quantity = 1;
              quantityController.text = "1";
              isMaxStockReached = false;
            });
            FocusScope.of(context).unfocus(); 
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            if (selectedProductId == null && textEditingController.text.isNotEmpty && selectedProductName.isEmpty) {
               WidgetsBinding.instance.addPostFrameCallback((_) => textEditingController.clear());
            }
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              textAlign: TextAlign.right,
              decoration: _inputStyle("ابحث عن اسم المنتج...", Icons.search, currentColor).copyWith(
                suffixIcon: selectedProductId != null 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          selectedProductId = null;
                          selectedProductName = "";
                          currentStock = 0;
                          currentCostPrice = 0.0;
                          quantity = 1;
                          quantityController.text = "1";
                          textEditingController.clear();
                        });
                      },
                    ) 
                  : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomerAutocomplete(Color currentColor) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('customers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        List<QueryDocumentSnapshot> customers = snapshot.data!.docs;
        return Autocomplete<QueryDocumentSnapshot>(
          displayStringForOption: (QueryDocumentSnapshot option) => option['fullName'],
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') return const Iterable<QueryDocumentSnapshot>.empty();
            return customers.where((QueryDocumentSnapshot option) => option['fullName'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (QueryDocumentSnapshot selection) {
            setState(() {
              selectedCustomerId = selection.id;
              selectedCustomerName = selection['fullName'];
            });
            FocusScope.of(context).unfocus();
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
             if (_customerFocusNode != focusNode) {
                if (_customerFocusNode != null) {
                   _customerFocusNode!.removeListener(_onFocusChange);
                }
                _customerFocusNode = focusNode;
                _customerFocusNode!.addListener(_onFocusChange);
             }
             
             if (selectedCustomerId == null && textEditingController.text.isNotEmpty && selectedCustomerName.isEmpty) {
               WidgetsBinding.instance.addPostFrameCallback((_) => textEditingController.clear());
            }
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              textAlign: TextAlign.right,
              decoration: _inputStyle("ابحث عن اسم الزبون...", Icons.person_search, currentColor).copyWith(
                suffixIcon: selectedCustomerId != null ? const Icon(Icons.check_circle, color: Colors.green) : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCartTable() {
    return _buildSectionCard(
      title: "قائمة الأصناف",
      icon: Icons.list_alt,
      child: Consumer<CartProvider>( 
        builder: (context, cartProvider, child) {
          
          if (cartProvider.items.isEmpty) {
            return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("الفاتورة فارغة")));
          }

          return Column(
            children: cartProvider.items.map((item) {
              bool isRet = item.isReturn;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () {
                    context.read<CartProvider>().removeFromCart(item);
                  },
                ),
                title: Text(item.name, style: TextStyle(fontWeight: FontWeight.bold, color: isRet ? returnColor : Colors.black)),
                subtitle: Text("${item.qty} حبة × ${item.price} د.أ"),
                trailing: Text(
                  "${item.total.toStringAsFixed(2)} د.أ",
                  style: TextStyle(color: isRet ? returnColor : primaryColor, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildCheckoutSection(double debt, bool isCredit, Color currentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Selector<CartProvider, double>(
                selector: (context, provider) => provider.grandTotal,
                builder: (context, total, child) {
                  bool isCreditNow = total < 0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCreditNow ? "المبلغ المستحق للزبون:" : "المجموع الكلي:", 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(width: 20), 
                      Text(
                        "${total.abs().toStringAsFixed(2)} د.أ",
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold, 
                          color: isCreditNow ? returnColor : primaryColor
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),

          Divider(color: Colors.black.withOpacity(0.1), thickness: 1),
          if (!isCredit) ...[
            Row(
              children: [
                Expanded(child: _buildToggleButton("نقد (الآن)", !isDebtMode, () => setState(() => isDebtMode = false))),
                const SizedBox(width: 10),
                Expanded(child: _buildToggleButton("دين (ذمم)", isDebtMode, () => setState(() => isDebtMode = true))),
              ],
            ),
            if (isDebtMode) ...[
              const SizedBox(height: 10),
              _buildCustomerAutocomplete(currentColor),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cashPaidController,
                      focusNode: _cashFocusNode,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() {}),
                      decoration: _inputStyle("المدفوع كاش", Icons.money, currentColor).copyWith(
                        errorText: isPaymentError ? "أكبر من المجموع!" : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("المتبقي دين:", style: TextStyle(fontSize: 12, color: Colors.red)),
                      Text("${debt.toStringAsFixed(2)} د.أ", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                ],
              ),
            ],
          ] else ...[
             const Text("كيف تريد إرجاع الفرق للزبون؟", style: TextStyle(color: Colors.grey)),
             const SizedBox(height: 10),
             Row(
               children: [
                 Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: returnColor), onPressed: _processCheckout, child: const Text("إرجاع كاش", style: TextStyle(color: Colors.white, fontSize: 12)))),
                 const SizedBox(width: 10),
                 Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: primaryColor), onPressed: () { setState(() { isDebtMode = true; }); }, child: const Text("خصم من الدين", style: TextStyle(fontSize: 12)))),
               ],
             ),
             if (isDebtMode) ...[ 
                const SizedBox(height: 10),
                _buildCustomerAutocomplete(currentColor),
             ]
          ],
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: isPaymentError ? Colors.grey : currentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: isPaymentError ? null : _processCheckout, 
              icon: Icon(isCredit ? Icons.assignment_return : Icons.check_circle, color: Colors.white),
              label: Text(isCredit ? "تأكيد الإرجاع" : "إنهاء وحفظ الفاتورة", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(String name, String email) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: primaryColor),
            accountName: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Image.asset('assets/images/logo1.png', width: 110, height: 110, errorBuilder: (c, e, s) => Icon(Icons.store, color: primaryColor)),
            ),
          ),
          _buildDrawerItem(Icons.people, "الزبائن", const CustomersScreen()),
          _buildDrawerItem(Icons.inventory, "المنتجات", const ProductsScreen()),
          _buildDrawerItem(Icons.receipt_long, "الفواتير", const InvoicesScreen()),
          _buildDrawerItem(Icons.bar_chart, "الاستعلامات", const ReportsScreen()), 
          Divider(color: Colors.black.withOpacity(0.1), thickness: 1),
          ListTile(leading: Icon(Icons.settings, color: primaryColor), title: const Text("الإعدادات"), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen())); }),
        ],
      ),
    );
  }
  
  InputDecoration _inputStyle(String hint, IconData icon, Color color) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: color, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: color, width: 2), borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child, Color iconColor = const Color(0xFF6B8068)}) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: iconColor, size: 18), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))]),
          Divider(color: Colors.black.withOpacity(0.1), thickness: 1),
          child,
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: isSelected ? primaryColor : Colors.grey[200], borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text(text, style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Widget? page) {
    return ListTile(leading: Icon(icon, color: primaryColor), title: Text(title), onTap: () { Navigator.pop(context); if (page != null) Navigator.push(context, MaterialPageRoute(builder: (context) => page)); else _showSnackBar("صفحة $title قيد التطوير...", icon: Icons.construction, color: Colors.grey); });
  }
}