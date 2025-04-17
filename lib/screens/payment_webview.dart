import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../constants.dart';

class PaymentWebView extends StatefulWidget {
  final String url;

  const PaymentWebView({Key? key, required this.url}) : super(key: key);

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  bool isLoading = true;
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Handle specific redirects if needed
            if (request.url.contains('payment_success')) {
              // Handle successful payment
              Navigator.pop(context, true); // Return success status
              return NavigationDecision.prevent;
            }
            if (request.url.contains('payment_cancelled')) {
              // Handle cancelled payment
              Navigator.pop(context, false); // Return failure status
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('Cancel Payment?'),
                content: const Text(
                    'Are you sure you want to cancel this payment?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                    },
                    child: const Text('No', style: TextStyle(color: kDefaultColor)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Go back to cart
                    },
                    child: const Text('Yes', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: kDefaultColor),
            ),
        ],
      ),
    );
  }
}
