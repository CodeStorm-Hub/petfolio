import 'package:flutter_sslcommerz/model/SSLCCustomerInfoInitializer.dart';
import 'package:flutter_sslcommerz/model/SSLCSdkType.dart';
import 'package:flutter_sslcommerz/model/SSLCurrencyType.dart';
import 'package:flutter_sslcommerz/model/SSLCommerzInitialization.dart';
import 'package:flutter_sslcommerz/sslcommerz.dart';

class SslcommerzService {
  static const _storeId = String.fromEnvironment('SSLCOMMERZ_STORE_ID');
  static const _storePasswd = String.fromEnvironment('SSLCOMMERZ_STORE_PASSWD');
  static const _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jqyjvhwlcqcsuwcqgcwf.supabase.co',
  );

  static const _multiCardForMethod = {
    'bkash':       'bKash',
    'nagad':       'nagad',
    'sslcommerz':  '',      // empty = show all SSLCommerz options (cards, MFS, etc.)
  };

  static Future<SslPayResult> pay({
    required String orderId,
    required double amountBdt,
    required String paymentMethodName,
    String customerName = 'Customer',
    String customerEmail = 'customer@petfolio.app',
    String customerPhone = '01700000000',
  }) async {
    final multiCard = _multiCardForMethod[paymentMethodName] ?? paymentMethodName;
    final ipnUrl = '$_supabaseUrl/functions/v1/sslcommerz-webhook';

    final initialization = SSLCommerzInitialization(
      store_id:         _storeId,
      store_passwd:     _storePasswd,
      total_amount:     amountBdt,
      currency:         SSLCurrencyType.BDT,
      tran_id:          orderId,
      product_category: 'Pet Supplies',
      sdkType:          SSLCSdkType.TESTBOX,
      ipn_url:          ipnUrl,
      multi_card_name:  multiCard,
    );

    final sslcommerz = Sslcommerz(initializer: initialization)
        .addCustomerInfoInitializer(
          customerInfoInitializer: SSLCCustomerInfoInitializer(
            customerName:     customerName,
            customerEmail:    customerEmail,
            customerPhone:    customerPhone,
            customerAddress1: 'Dhaka',
            customerCity:     'Dhaka',
            customerState:    'Dhaka',
            customerPostCode: '1000',
            customerCountry:  'Bangladesh',
          ),
        );

    final result = await sslcommerz.payNow();

    return switch (result.status?.toLowerCase()) {
      'closed' => SslPayResult.cancelled,
      'failed'  => SslPayResult.failed,
      _         => SslPayResult.success,
    };
  }
}

enum SslPayResult { success, cancelled, failed }
