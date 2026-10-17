import 'package:flutter/material.dart';
import '../models/motor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentScreen extends StatefulWidget {
  final Motor motor;
  final String userId;

  const PaymentScreen({
    super.key,
    required this.motor,
    required this.userId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {

  final amountController = TextEditingController();
  bool loading = false;

  Future<void> addPayment() async {
    setState(() {
      loading = true;
    });

    try {
      double amount = double.parse(amountController.text);

      final motorRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('motors')
          .doc(widget.motor.id);

      await motorRef.update({
        'paidAmount': widget.motor.paidAmount + amount,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment Added 🔥")),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),

      appBar: AppBar(
        title: const Text("Add Payment"),
        backgroundColor: Colors.green,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            Text(
              widget.motor.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter Payment Amount",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : addPayment,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Payment"),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "Remaining Balance: ₱${widget.motor.balance}",
              style: const TextStyle(color: Colors.redAccent),
            ),

          ],
        ),
      ),
    );
  }
}