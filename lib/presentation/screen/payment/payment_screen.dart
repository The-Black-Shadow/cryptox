import 'package:cryptox/logic/bloc/payment/payment_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final amountController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe Payment (BLoC)'),
        backgroundColor: Colors.deepPurple,
      ),
      // BlocConsumer is perfect for listening to state changes for actions (like dialogs)
      // and rebuilding the UI when needed (like showing a loading spinner).
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            showDialog(
              context: context,
              builder: (_) => const AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 100.0),
                    SizedBox(height: 10.0),
                    Text("Payment Successful!"),
                  ],
                ),
              ),
            );
          } else if (state is PaymentFailure) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cancel, color: Colors.red, size: 100.0),
                    const SizedBox(height: 10.0),
                    Text("Payment Failed: ${state.error}"),
                  ],
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          // Show a loading indicator while payment is processing
          if (state is PaymentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show the main payment UI
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Enter Amount',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(fontSize: 22),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText: 'e.g., 50.00',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.deepPurple,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    if (amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter an amount')),
                      );
                      return;
                    }
                    // Add the event to trigger the BLoC
                    context.read<PaymentBloc>().add(
                      PaymentRequested(
                        amount: amountController.text,
                        currency: 'USD',
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Pay with Stripe',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
