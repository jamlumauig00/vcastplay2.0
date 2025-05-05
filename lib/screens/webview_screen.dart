import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:open_file/open_file.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../utils/permissions_helper.dart';
import '../widgets/loading_animation.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late InAppWebViewController webViewController;
  //final ScreenshotController screenshotController = ScreenshotController();
  bool _permissionsGranted = false;
  bool _showSplash = false;
  bool _webViewLoaded = true;
  bool _jsSystemLoadReceived = true;
  int _backPressedCount = 0;

  //Added 04/03
  InAppWebViewSettings settings = InAppWebViewSettings(
    javaScriptEnabled: true, // Enable JavaScript
    mediaPlaybackRequiresUserGesture: false, // Allow autoplay for media
  );

  // - - - - -

  final String webUrl = "https://api.caltondatx.com/public/contents/197e0969-102d-4071-a808-5edfb001b410-77RYRNNP78X9K.html";
  //final String webUrl = "https://analytics.caltondatx.com/";

  String? generatedPdfFilePath;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (_permissionsGranted) return;
    _permissionsGranted = true;

    try {
      await PermissionHelper.requestPermissions();
    } catch (e) {
      _permissionsGranted = false;
    }
  }

  Widget _buildSplashOverlay() {
    return Stack(
      // ✅ Correct: Wrap Positioned inside a Stack
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                ),
                const Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(child: LoadingTextAnimation()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebView() {
    return Offstage(
      offstage: !_permissionsGranted,
      child: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(webUrl)),
        // ignore: deprecated_member_use
        initialOptions: InAppWebViewGroupOptions(
          // ignore: deprecated_member_use
          crossPlatform: InAppWebViewOptions(
            mediaPlaybackRequiresUserGesture: false,
            disableHorizontalScroll: false,
            disableVerticalScroll: false, // Ensure scrolling is enabled
            supportZoom: false,
            //allowsInlineMediaPlayback: true,
          ),
          // ignore: deprecated_member_use
          ios: IOSInAppWebViewOptions(
            sharedCookiesEnabled: true,
            allowsLinkPreview: false, // Disables long press preview on iOS
            allowsBackForwardNavigationGestures: true,
            isPagingEnabled: false, // Ensures better scrolling behavior
            allowsInlineMediaPlayback: true,
            allowsAirPlayForMediaPlayback: true,
            scrollsToTop: true,
          ),
        ),
        onPermissionRequest: (controller, request) async {
          return PermissionResponse(
            resources: request.resources,
            action: PermissionResponseAction.GRANT,
          );
        },
        initialSettings: InAppWebViewSettings(
          allowsBackForwardNavigationGestures:
              true, // Enables swipe gestures in iOS
          isInspectable: true,
          disallowOverScroll: false,
          cacheEnabled: true,
          useShouldInterceptRequest: false, // Allow WebView to manage caching
          useOnLoadResource: true,
          useHybridComposition: true,
          javaScriptEnabled: true,
          allowFileAccessFromFileURLs: true,
          allowUniversalAccessFromFileURLs: true,
          //javascriptMode: JavascriptMode.unrestricted, // Enable JavaScript
          allowsInlineMediaPlayback: true,
          allowsLinkPreview: false,
          mediaPlaybackRequiresUserGesture: false,
          builtInZoomControls: false,
          displayZoomControls: false,
          supportZoom: false,
          allowFileAccess: true,
          disableContextMenu: true,
        ),
        onWebViewCreated: (controller) {
          webViewController = controller;

        },
        /*  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        }, */
        onLoadStop: (controller, url) async {
          //_refreshController.refreshCompleted();


        },

        // ignore: deprecated_member_use
        onLoadError: (controller, url, code, message) {

        },
        onReceivedError: (controller, request, error) {

        },
        onProgressChanged: (controller, progress) {
          setState(() {
            if (progress >= 100) {
              _webViewLoaded = true;
              _jsSystemLoadReceived = false;

              _maybeHideSplash();
            }
          });
        },

        // ignore: deprecated_member_use
        androidOnPermissionRequest: (controller, origin, resources) async {
          // ignore: deprecated_member_use
          return PermissionRequestResponse(
            resources: resources,
            // ignore: deprecated_member_use
            action: PermissionRequestResponseAction.GRANT,
          );
        },
        onDownloadStartRequest: (controller, url) async {

        },
        onConsoleMessage: (controller, consoleMessage) async {
          try {
            // Check if the message is a JSON string and try to decode it.
            var message = consoleMessage.message;
            try {
              final decodedMessage = jsonDecode(message);
              // If decoding succeeds, log the decoded message.

            } catch (e) {
              // If not a valid JSON, log the raw message.
            }
          } catch (e) {

          }

          /* 
          if (consoleMessage.message.contains(
            "Speech Recognition Error: not-allowed",
          )) {
            await Permission.microphone.request();
          } */

         /* if (consoleMessage.message.contains("System Load")) {
            *//*   setState(() {
               
              }); *//*
            _jsSystemLoadReceived = true;
            _maybeHideSplash(); // Make sure this method does not call `setState()` unnecessarily
          }*/
        },
      ),
    );
  }

  void _maybeHideSplash() {
    if (_webViewLoaded && _jsSystemLoadReceived) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    // If the WebView can navigate back, do so.
    if (await webViewController.canGoBack()) {
      webViewController.goBack();
      _backPressedCount = 0; // Reset the counter on WebView navigation.
      return false;
    }
    // If no back history exists in the WebView.
    if (_backPressedCount == 0) {
      // First press: show message and increment counter.
      _backPressedCount++;
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(const SnackBar(content: Text("Press back twice to exit")));
      return false;
    } else {
      // Second press: exit the app.
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            // ✅ WebView is positioned correctly
            Positioned.fill(
              child: SafeArea(
                bottom: false, // Adjust as needed
                child: _buildWebView(),
              ),
            ),
            if (_showSplash || !_permissionsGranted)
              AnimatedOpacity(
                opacity: _showSplash || !_permissionsGranted ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: _buildSplashOverlay(),
              ),
          ],
        ),
      ),
    );
  }

}
