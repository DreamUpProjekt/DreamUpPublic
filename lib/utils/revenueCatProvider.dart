import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RevenueCatProvider with ChangeNotifier {
  static final String _apiKey = Platform.isIOS
      ? '*********************************'
      : '*********************************';

  bool _isSubscriptionActive = false;
  DateTime? _subscriptionExpirationDate;

  bool get isSubscriptionActive => _isSubscriptionActive;
  DateTime? get subscriptionExpirationDate => _subscriptionExpirationDate;

  RevenueCatProvider() {
    print('provider is initialized');

    _init();
  }

  Future<void> _init() async {
    await initPurchases();
    await _fetchSubscriptionStatus();
    Purchases.addCustomerInfoUpdateListener(_customerInfoUpdated);
  }

  Future<void> initPurchases() async {
    await Purchases.setLogLevel(LogLevel.debug);
    var configuration = PurchasesConfiguration(_apiKey);

    try {
      await Purchases.configure(configuration);
      print('Initialization of purchase API was successful');
    } catch (e) {
      print('An error occurred while configuration: $e');
    }
  }

  void _customerInfoUpdated(CustomerInfo customerInfo) {
    bool isActive =
        customerInfo.entitlements.all['DreamUpPremium']?.isActive ?? false;
    DateTime? expirationDate = customerInfo
                .entitlements.all['DreamUpPremium']?.expirationDate !=
            null
        ? DateTime.parse(
            customerInfo.entitlements.all['DreamUpPremium']!.expirationDate!)
        : null;

    if (_isSubscriptionActive != isActive ||
        _subscriptionExpirationDate != expirationDate) {
      _isSubscriptionActive = isActive;
      _subscriptionExpirationDate = expirationDate;
      print(
          'Subscription status changed: $_isSubscriptionActive, Expiration Date: $_subscriptionExpirationDate');
      notifyListeners();
    }
  }

  Future<void> _fetchSubscriptionStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      bool isActive =
          customerInfo.entitlements.all['DreamUpPremium']?.isActive ?? false;
      DateTime? expirationDate = customerInfo
                  .entitlements.all['DreamUpPremium']?.expirationDate !=
              null
          ? DateTime.parse(
              customerInfo.entitlements.all['DreamUpPremium']!.expirationDate!)
          : null;

      if (_isSubscriptionActive != isActive ||
          _subscriptionExpirationDate != expirationDate) {
        _isSubscriptionActive = isActive;

        print('user has subscription: $_isSubscriptionActive');

        _subscriptionExpirationDate = expirationDate;
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching subscription status: $e");
    }
  }

  Future<List<Offering>> fetchOffers() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      return current == null ? [] : [current];
    } on PlatformException catch (e) {
      print('An error has occured while fetching offers: $e');

      return [];
    }
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      // Refresh subscription status after purchase
      await _fetchSubscriptionStatus();
      return true;
    } catch (e) {
      print('An error has occurred while trying to purchase: $e');
      return false;
    }
  }

  Future<void> cancelSubscription() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      var link = customerInfo.managementURL;
      if (link != null) {
        var uri = (Uri.parse(link));
        launchUrl(uri);
      }
    } catch (e) {
      print("Error cancelling subscription: $e");
    }
  }

  @override
  void dispose() {
    Purchases.removeCustomerInfoUpdateListener(_customerInfoUpdated);
    super.dispose();
  }
}
