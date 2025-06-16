import 'package:bloc/bloc.dart';
import 'package:cryptox/data/repositories/wallet_repository.dart';
import 'package:equatable/equatable.dart';

part 'send_crypto_event.dart';
part 'send_crypto_state.dart';

class SendCryptoBloc extends Bloc<SendCryptoEvent, SendCryptoState> {
  final WalletRepository _walletRepository;

  SendCryptoBloc({required WalletRepository walletRepository})
      : _walletRepository = walletRepository,
        super(SendCryptoInitial()) {
    on<SendTetherSubmitted>(_onSendTetherSubmitted);
    // When the ResetSendCrypto event is received, emit the initial state.
    on<ResetSendCrypto>((event, emit) {
      emit(SendCryptoInitial());
    });
  }

  Future<void> _onSendTetherSubmitted(
    SendTetherSubmitted event,
    Emitter<SendCryptoState> emit,
  ) async {
    // Show a loading/in-progress state to the UI
    emit(SendCryptoInProgress());
    try {
      // Call the correct method from the repository
      await _walletRepository.sendTether(
        recipientEmail: event.recipientEmail,
        amountToSend: event.amount,
      );
      // On success, emit a success state with a confirmation message
      emit(SendCryptoSuccess('Successfully sent ${event.amount} USDT to ${event.recipientEmail}'));
    } catch (e) {
      // If an error occurs, emit a failure state with the error message
      emit(SendCryptoFailure(e.toString().replaceFirst("Exception: ", "")));
    }
  }
}
