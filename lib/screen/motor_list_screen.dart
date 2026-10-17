import 'package:flutter/material.dart';
import '../models/motor.dart';
import '../services/motor_service.dart';
import 'motor_details_screen.dart';

class MotorListScreen extends StatelessWidget {
  MotorListScreen({super.key});

  final MotorService service = MotorService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("My Motors"),
      ),

      body: StreamBuilder<List<Motor>>(
        stream: service.getMotors(),

        builder: (context, snapshot) {

          // 🔄 LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ❌ ERROR
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            );
          }

          // 📭 EMPTY
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No motors added yet",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
            );
          }

          // ✅ DATA
          final motors = snapshot.data!;

          return ListView.builder(
            itemCount: motors.length,

            itemBuilder: (context, index) {

              final motor = motors[index];

              return Card(
                color: Colors.grey[900],

                margin: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                child: ListTile(

                  title: Text(
                    motor.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const SizedBox(height: 5),

                      Text(
                        "Price: ₱${motor.price.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),

                      Text(
                        "Paid: ₱${motor.paidAmount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.greenAccent,
                        ),
                      ),

                      Text(
                        "Balance: ₱${motor.balance.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                        ),
                      ),

                    ],
                  ),

                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),

                  // 🚀 OPEN DETAILS SCREEN
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(

                        pageBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                        ) {
                          return MotorDetailsScreen(
                            motor: motor,
                          );
                        },

                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {

                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;

                          const curve = Curves.easeInOut;

                          final tween = Tween(
                            begin: begin,
                            end: end,
                          ).chain(
                            CurveTween(curve: curve),
                          );

                          final offsetAnimation =
                              animation.drive(tween);

                          return SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          );
                        },

                        transitionDuration:
                            const Duration(milliseconds: 300),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}