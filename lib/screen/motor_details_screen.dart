import 'package:flutter/material.dart';
import '../models/motor.dart';
import '../services/motor_service.dart';

class MotorDetailsScreen extends StatefulWidget {
  final Motor motor;

  const MotorDetailsScreen({super.key, required this.motor});

  @override
  State<MotorDetailsScreen> createState() => _MotorDetailsScreenState();
}

class _MotorDetailsScreenState extends State<MotorDetailsScreen> {
  final MotorService service = MotorService();

  final TextEditingController paymentController = TextEditingController();

  late Motor motor;

  @override
  void initState() {
    super.initState();
    motor = widget.motor;
  }

  Future<void> addPayment() async {
    final amount = double.tryParse(paymentController.text);

    if (amount == null || amount <= 0) return;

    await service.addPayment(
      motorId: motor.id,
      amount: amount,
    );

    setState(() {
      motor.paidAmount += amount;
    });

    paymentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = motor.balance;
    final progress = (motor.paidAmount / (motor.price - motor.downPayment));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Motor Details"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              motor.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // 📊 PROGRESS BAR
            LinearProgressIndicator(
              value: progress.isNaN ? 0 : progress,
              backgroundColor: Colors.grey,
              color: Colors.greenAccent,
              minHeight: 10,
            ),

            const SizedBox(height: 20),

            _info("Total Price", "₱${motor.price}"),
            _info("Downpayment", "₱${motor.downPayment}"),
            _info("Paid", "₱${motor.paidAmount}"),
            _info("Remaining", "₱$remaining"),
            _info("Monthly Due", "₱${motor.monthlyDue.toStringAsFixed(2)}"),

            const SizedBox(height: 30),

            // 💳 PAYMENT INPUT
            TextField(
              controller: paymentController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter payment amount",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: addPayment,
                child: const Text("Add Payment"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}