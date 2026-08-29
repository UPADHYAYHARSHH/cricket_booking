import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';

class CashfreeService {
  // Singleton pattern
  static final CashfreeService _instance = CashfreeService._internal();
  factory CashfreeService() => _instance;
  CashfreeService._internal();

  final CFPaymentGatewayService _cfPaymentGatewayService = CFPaymentGatewayService();

  Function(String orderId)? _onSuccess;
  Function(CFErrorResponse error, String orderId)? _onError;

  void init() {
    _cfPaymentGatewayService.setCallback(verifyPayment, onError);
  }

  void setCheckoutCallbacks({
    required Function(String orderId) onSuccess,
    required Function(CFErrorResponse error, String orderId) onError,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;
  }

  void verifyPayment(String orderId) {
    debugPrint("Verify Payment for order: $orderId");
    if (_onSuccess != null) {
      _onSuccess!(orderId);
    }
  }

  void onError(CFErrorResponse error, String orderId) {
    debugPrint("Payment Error: ${error.getMessage()} for order: $orderId");
    if (_onError != null) {
      _onError!(error, orderId);
    }
  }

  CFSession? createSession({
    required String orderId, 
    required String paymentSessionId, 
    CFEnvironment environment = CFEnvironment.SANDBOX
  }) {
    try {
      var session = CFSessionBuilder()
          .setEnvironment(environment)
          .setOrderId(orderId)
          .setPaymentSessionId(paymentSessionId)
          .build();
      return session;
    } on CFException catch (e) {
      debugPrint("Error creating session: ${e.message}");
      return null;
    }
  }

  void doPayment({
    required String orderId, 
    required String paymentSessionId, 
    CFEnvironment environment = CFEnvironment.SANDBOX,
  }) {
    try {
      var session = createSession(orderId: orderId, paymentSessionId: paymentSessionId, environment: environment);
      if (session == null) return;
      
      if (kIsWeb) {
        var cfDropCheckoutPayment = CFDropCheckoutPaymentBuilder()
            .setSession(session)
            .build();
        _cfPaymentGatewayService.doPayment(cfDropCheckoutPayment as dynamic);
      } else {
        var cfWebCheckoutPayment = CFWebCheckoutPaymentBuilder()
            .setSession(session)
            .build();
        _cfPaymentGatewayService.doPayment(cfWebCheckoutPayment as dynamic);
      }
      
    } on CFException catch (e) {
      debugPrint("Error starting payment: ${e.message}");
    } catch (e) {
      debugPrint("Unexpected Error: $e");
    }
  }
}
