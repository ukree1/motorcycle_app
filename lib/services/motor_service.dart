import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/motor.dart';

class MotorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current user id, or null when nobody is logged in.
  /// (The old `currentUser!.uid` threw a null-check error.)
  String? get _uidOrNull => _auth.currentUser?.uid;

  String get uid {
    final id = _uidOrNull;
    if (id == null) {
      throw StateError('No logged in user. Please log in again.');
    }
    return id;
  }

  CollectionReference<Map<String, dynamic>> get _motorsRef =>
      _db.collection('users').doc(uid).collection('motors');

  // 🚀 ADD MOTOR
  Future<String> addMotor(Motor motor) async {
    final doc = await _motorsRef.add({
      ...motor.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // ✏️ UPDATE MOTOR (details only, payments go through addPayment)
  Future<void> updateMotor(Motor motor) async {
    await _motorsRef.doc(motor.id).update({
      'name': motor.name,
      'price': motor.price,
      'downPayment': motor.downPayment,
      'months': motor.months,
    });
  }

  // 🗑️ DELETE MOTOR (and its payment history)
  Future<void> deleteMotor(String motorId) async {
    final motorRef = _motorsRef.doc(motorId);
    final payments = await motorRef.collection('payments').get();

    final batch = _db.batch();
    for (final p in payments.docs) {
      batch.delete(p.reference);
    }
    batch.delete(motorRef);
    await batch.commit();
  }

  // 🚀 GET MOTORS (live stream)
  Stream<List<Motor>> getMotors() {
    // Surface a clear error instead of crashing when logged out.
    if (_uidOrNull == null) {
      return Stream<List<Motor>>.error(
        StateError('No logged in user. Please log in again.'),
      );
    }

    return _motorsRef.snapshots().map((snapshot) {
      final motors = <Motor>[];

      for (final doc in snapshot.docs) {
        try {
          motors.add(Motor.fromDoc(doc));
        } catch (e) {
          // One bad document should not break the whole dashboard.
          debugPrint('Skipping invalid motor ${doc.id}: $e');
        }
      }

      // Newest first; documents without createdAt go last.
      motors.sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null && bDate == null) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      return motors;
    });
  }

  // 🚀 ADD PAYMENT (atomic: total and history are saved together)
  Future<void> addPayment({
    required String motorId,
    required double amount,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Payment amount must be greater than zero.');
    }

    final motorRef = _motorsRef.doc(motorId);
    final paymentRef = motorRef.collection('payments').doc();

    final batch = _db.batch();
    batch.update(motorRef, {'paidAmount': FieldValue.increment(amount)});
    batch.set(paymentRef, {
      'amount': amount,
      'date': Timestamp.now(),
    });
    await batch.commit();
  }
}