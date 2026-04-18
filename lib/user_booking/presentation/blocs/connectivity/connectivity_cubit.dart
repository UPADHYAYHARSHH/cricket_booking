import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ConnectivityStatus { connected, disconnected }

abstract class ConnectivityState {}

class ConnectivityInitial extends ConnectivityState {}

class ConnectivityConnected extends ConnectivityState {}

class ConnectivityDisconnected extends ConnectivityState {}

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity _connectivity;
  StreamSubscription? _connectivitySubscription;

  ConnectivityCubit(this._connectivity) : super(ConnectivityInitial()) {
    _checkInitialConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // connectivity_plus 6.x returns a List<ConnectivityResult>
    // If any of the results is not 'none', we are connected.
    if (results.contains(ConnectivityResult.none) && results.length == 1) {
      emit(ConnectivityDisconnected());
    } else if (results.isEmpty) {
      emit(ConnectivityDisconnected());
    } else {
      emit(ConnectivityConnected());
    }
  }

  Future<void> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
