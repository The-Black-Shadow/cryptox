import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  PaymentBloc() : super(PaymentInitial()) {
    on<PaymentRequested>(_onPaymentRequested);
  }

  Future<void> _onPaymentRequested(
    PaymentRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      // 1. Create payment intent
      final paymentIntent = await _createPaymentIntent(event.amount, event.currency);

      if (paymentIntent == null) {
        throw Exception('Failed to create payment intent.');
      }

      // 2. Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'Flutter Stripe Demo',
          style: ThemeMode.light,
        ),
      );

      // 3. Present the payment sheet
      await Stripe.instance.presentPaymentSheet();

      emit(PaymentSuccess());
    } on StripeException catch (e) {
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