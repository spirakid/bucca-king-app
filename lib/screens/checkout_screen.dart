import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/colors.dart';
import '../providers/cart_provider.dart';
import '../services/auth_service.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}
class _CheckoutScreenState extends State<CheckoutScreen> {
  final AuthService _authService = AuthService();
  String _selectedPayment = 'cash';
  bool _isProcessing = false;
  
  String _userName = '';
  String _userPhone = '';
  String _userAddress = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final profile = await _authService.getUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _userName = profile['name'] ?? '';
        _userPhone = profile['phone'] ?? '';
        _userAddress = profile['address'] ?? '';
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_userName.isEmpty || _userPhone.isEmpty || _userAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete your profile first', style: GoogleFonts.poppins()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      
      final orderData = {
        'userId': _authService.userId,
        'userName': _userName,
        'userPhone': _userPhone,
        'userAddress': _userAddress,
        'items': cart.items.values.map((item) => {
          'id': item.id,
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
        }).toList(),
        'subtotal': cart.totalAmount,
        'deliveryFee': cart.deliveryFee,
        'total': cart.grandTotal,
        'paymentMethod': _selectedPayment,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestore.instance.collection('orders').add(orderData);

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': _authService.userId,
        'title': '🎉 Order Placed Successfully!',
        'body': 'Your order has been received and is being prepared.',
        'type': 'order_status',
        'orderId': docRef.id,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      cart.clear();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(orderId: docRef.id),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Checkout', style: GoogleFonts.poppins(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Information', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(_userName.isNotEmpty ? _userName : 'Not set', style: GoogleFonts.poppins()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(_userPhone.isNotEmpty ? _userPhone : 'Not set', style: GoogleFonts.poppins()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _userAddress.isNotEmpty ? _userAddress : 'Not set',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Payment Method', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPaymentOption('cash', 'Cash on Delivery', Icons.money, 'Pay when your order arrives'),
            _buildPaymentOption('card', 'Card Payment', Icons.credit_card, 'Coming Soon'),
            _buildPaymentOption('transfer', 'Bank Transfer', Icons.account_balance, 'Coming Soon'),
            const SizedBox(height: 24),
            Text('Order Summary', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Subtotal', '₦${cart.totalAmount.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Delivery Fee', '₦${cart.deliveryFee.toStringAsFixed(0)}'),
                  const Divider(height: 24),
                  _buildSummaryRow('Total', '₦${cart.grandTotal.toStringAsFixed(0)}', isTotal: true),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Place Order', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String value, String title, IconData icon, String subtitle) {
    final isDisabled = value != 'cash';
    
    return GestureDetector(
      onTap: isDisabled ? null : () => setState(() => _selectedPayment = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDisabled ? AppColors.background : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedPayment == value && !isDisabled ? AppColors.primary : AppColors.border,
            width: _selectedPayment == value && !isDisabled ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDisabled ? AppColors.textLight : (_selectedPayment == value ? AppColors.primary : AppColors.textSecondary),
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: isDisabled ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPayment,
              onChanged: isDisabled ? null : (v) => setState(() => _selectedPayment = v!),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}