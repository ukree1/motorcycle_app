import 'package:flutter/material.dart';
import '../models/motor.dart';
import '../services/motor_service.dart';

class AddMotorScreen extends StatefulWidget {
  const AddMotorScreen({super.key});

  @override
  State<AddMotorScreen> createState() => _AddMotorScreenState();
}

class _AddMotorScreenState extends State<AddMotorScreen> {

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final downController = TextEditingController();
  final monthsController = TextEditingController();

  final MotorService motorService = MotorService();

  bool loading = false;

  addMotor() async {
    setState(() {
      loading = true;
    });

    try {
      final motor = Motor(
        id: '',
        name: nameController.text,
        price: double.parse(priceController.text),
        downPayment: double.parse(downController.text),
        months: int.parse(monthsController.text),
      );

      await motorService.addMotor(motor);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Motor Added Successfully 🔥")),
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
        title: const Text("Add Motor"),
        backgroundColor: Colors.green,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            _input(nameController, "Motor Name"),
            _input(priceController, "Total Price"),
            _input(downController, "Downpayment"),
            _input(monthsController, "Months (e.g. 12, 24)"),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : addMotor,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Motor"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}