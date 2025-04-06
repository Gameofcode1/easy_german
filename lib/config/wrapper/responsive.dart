import 'package:flutter/material.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget mobileView;
  final Widget webView;

  const ResponsiveWrapper({
    super.key,
    required this.mobileView,
    required this.webView,
  });

  @override
  Widget build(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width > 800; // Threshold for web
    return isWeb ? webView : mobileView;
  }
}