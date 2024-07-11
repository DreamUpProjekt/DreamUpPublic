import 'package:flutter/material.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';

class PaywallWidget extends StatefulWidget {
  final String title;
  final String description;
  final List<Package> packages;
  final ValueChanged<Package> onClickedPackage;

  const PaywallWidget({
    super.key,
    required this.title,
    required this.description,
    required this.packages,
    required this.onClickedPackage,
  });

  @override
  State<PaywallWidget> createState() => _PaywallWidgetState();
}

class _PaywallWidgetState extends State<PaywallWidget> {
  Widget buildPackages() => ListView.builder(
        shrinkWrap: true,
        primary: false,
        itemCount: widget.packages.length,
        itemBuilder: (context, index) {
          final package = widget.packages[index];

          return buildPackage(context, package);
        },
      );

  Widget buildPackage(BuildContext context, Package package) {
    final product = package.storeProduct;

    return Card(
      color: Colors.blueAccent.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        title: Text(
          product.title,
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          product.description,
        ),
        trailing: Text(
          product.priceString,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => widget.onClickedPackage(package),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(100),
          topRight: Radius.circular(100),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              widget.description,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            buildPackages(),
          ],
        ),
      ),
    );
  }
}
