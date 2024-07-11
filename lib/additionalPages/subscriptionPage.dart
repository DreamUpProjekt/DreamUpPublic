import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_size/flutter_keyboard_size.dart';
import 'package:intl/intl.dart';

import '../utils/revenueCatProvider.dart';
import '../widgets/paywallWidget.dart';

//pc test

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  Future<void> fetchOffers() async {
    try {
      final offerings =
          await Provider.of<RevenueCatProvider>(context, listen: false)
              .fetchOffers();
      if (offerings.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keine möglichen Subscriptions gefunden!'),
          ),
        );
      } else {
        final offer = offerings.first;
        print('Offer: $offer');

        final packages = offerings
            .map((offer) => offer.availablePackages)
            .expand((pair) => pair)
            .toList();

        showModalBottomSheet(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          context: context,
          builder: (builderContext) => PaywallWidget(
            title: 'Abo abschließen',
            description: 'Schließe ein Premium Abo ab!',
            packages: packages,
            onClickedPackage: (package) async {
              await Provider.of<RevenueCatProvider>(builderContext,
                      listen: false)
                  .purchasePackage(package)
                  .then((value) async {
                Navigator.pop(builderContext); // Verwende builderContext hier
              });
            },
          ),
        );
      }
    } on PlatformException catch (e) {
      print('An error occurred while fetching offers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while fetching offers: $e'),
        ),
      );
    }
  }

  String formatDate(DateTime dateTime) {
    return DateFormat('dd.MM.yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.95),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            color: Colors.transparent,
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black87,
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Premium',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<RevenueCatProvider>(
        builder: (context, revenueCatProvider, _) {
          return SizedBox.expand(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 30,
                      ),
                      child: Center(
                        child: Text(
                          revenueCatProvider.isSubscriptionActive
                              ? 'Abonnement aktiv bis: ${formatDate(revenueCatProvider.subscriptionExpirationDate!)}'
                              : 'Kein aktives Abonnement',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  Center(
                    child: IntrinsicWidth(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blueAccent,
                            width: 2,
                          ),
                          color: revenueCatProvider.isSubscriptionActive
                              ? Colors.white
                              : Colors.blueAccent,
                        ),
                        child: Center(
                          child: GestureDetector(
                            onTap: () async {
                              if (revenueCatProvider.isSubscriptionActive) {
                                // Wenn das Abonnement aktiv ist, Kündigungslogik ausführen
                                await revenueCatProvider.cancelSubscription();
                              } else {
                                // Wenn kein Abonnement aktiv ist, Angebote abrufen
                                await fetchOffers();
                              }
                            },
                            child: Text(
                              revenueCatProvider.isSubscriptionActive
                                  ? 'Premium kündigen'
                                  : 'Premium abschließen',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: revenueCatProvider.isSubscriptionActive
                                    ? Colors.blueAccent
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
