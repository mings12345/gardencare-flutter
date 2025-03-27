import 'package:flutter/material.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final double amount;
  final String bookingId;
  
  const PaymentSuccessScreen({
    required this.amount,
    required this.bookingId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Successful')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 20),
              Text(
                'Payment Successful!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Text(
                'Amount: PHP ${amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Booking ID: $bookingId',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}