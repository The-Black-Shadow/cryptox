import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:cryptox/data/repositories/wallet_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final WalletRepository _walletRepository;

  PaymentBloc({required WalletRepository walletRepository})
      : _walletRepository = walletRepository,
        super(PaymentInitial()) {
    on<PaymentRequested>(_onPaymentRequested);
  }

  Future<void> _onPaymentRequested(
    PaymentRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      // 1. Create payment intent with Stripe
      final paymentIntent = await _createPaymentIntent(event.amount, event.currency);
      if (paymentIntent == null) {
        throw Exception('Failed to create payment intent.');
      }

      // 2. Initialize and present the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'CryptoX Deposit',
          style: ThemeMode.light,
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      // --- 3. UPDATED LOGIC ---
      // After successful payment, add funds as a new parcel.
      try {
        final double amountToAdd = double.parse(event.amount);
        // Call the new method to create a traceable parcel for the deposit
        await _walletRepository.addTetherAsParcel(amountToAdd: amountToAdd);
        
        // Emit success state with the amount added
        emit(PaymentSuccess(amountAdded: event.amount));
      } catch (e) {
        // This is a critical error: payment succeeded but crediting failed.
        emit(PaymentFailure(
          error: 'Payment was successful, but updating your balance failed. Please contact support.',
        ));
      }
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        emit(PaymentInitial()); // User cancelled, go back to initial state
        return;
      }
      debugPrint('Stripe payment failed: ${e.error.localizedMessage}');
      emit(PaymentFailure(error: 'Payment failed: ${e.error.localizedMessage}'));
    } catch (e) {
      debugPrint('An unexpected error occurred: $e');
      emit(PaymentFailure(error: 'An unexpected error occurred: $e'));
    }
  }

  Future<Map<String, dynamic>?> _createPaymentIntent(
    String amount,
    String currency,
  ) async {
    // This logic remains the same
    try {
      final calculatedAmount = (double.parse(amount) * 100).round().toString();
      Map<String, dynamic> body = {
        'amount': calculatedAmount,
        'currency': currency,
        'payment_method_types[]': 'card',
      };
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['STRIPE_SECRET_KEY']}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}