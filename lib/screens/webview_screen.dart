import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/history_provider.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final UserData userData;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.userData,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _loadingProgress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Request'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isLoading)
            Container(
              margin: const EdgeInsets.all(16),
              width: 20,
              height: 20,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Loading Progress Bar
          if (_isLoading)
            LinearProgressIndicator(
              value: _loadingProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          
          // WebView
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStart: (controller, url) {
                setState(() {
                  _isLoading = true;
                  _loadingProgress = 0;
                });
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  _loadingProgress = progress / 100;
                });
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  _isLoading = false;
                });
                
                // Auto-populate form fields after page loads
                await _populateFormFields();
                
                // Check for submission results in the current URL
                _checkSubmissionResult(url?.toString() ?? '');
              },
              onUpdateVisitedHistory: (controller, url, isReload) {
                // Monitor URL changes to detect submission results
                _checkSubmissionResult(url?.toString() ?? '');
              },
              initialSettings: InAppWebViewSettings(
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: Text(
          'Form will be automatically populated with your saved information',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _populateFormFields() async {
    if (_webViewController == null) return;

    // JavaScript to populate form fields
    final jsCode = '''
      (function() {
        try {
          // Title/Salutation
          var salutationField = document.querySelector('select[name="salutation"], #salutation');
          if (salutationField) {
            salutationField.value = "${widget.userData.title == 'Mr.' ? 'Monsieur' : 'Madame'}";
          }

          // First Name
          var firstNameField = document.querySelector('input[name="prenom"], #prenom');
          if (firstNameField) {
            firstNameField.value = "${widget.userData.firstName}";
          }

          // Last Name
          var lastNameField = document.querySelector('input[name="nom"], #nom');
          if (lastNameField) {
            lastNameField.value = "${widget.userData.lastName}";
          }

          // Phone
          var phoneField = document.querySelector('input[name="telephone"], #telephone');
          if (phoneField) {
            phoneField.value = "${widget.userData.phone}";
          }

          // Email
          var emailField = document.querySelector('input[name="courriel"], #courriel');
          if (emailField) {
            emailField.value = "${widget.userData.email}";
          }

          // Project
          var projectField = document.querySelector('select[name="projet"], #projet');
          if (projectField) {
            projectField.value = "${widget.userData.realEstateProject}";
          }

          // Unit
          var unitField = document.querySelector('input[name="unite"], #unite');
          if (unitField) {
            unitField.value = "${widget.userData.unit}";
          }

          // Trigger change events to ensure form validation
          var fields = [salutationField, firstNameField, lastNameField, phoneField, emailField, projectField, unitField];
          fields.forEach(function(field) {
            if (field) {
              var event = new Event('change', { bubbles: true });
              field.dispatchEvent(event);
            }
          });

          return "Form populated successfully";
        } catch (error) {
          return "Error populating form: " + error.message;
        }
      })();
    ''';

    try {
      final result = await _webViewController!.evaluateJavascript(source: jsCode);
      print('Form population result: $result');
    } catch (e) {
      print('Error populating form: $e');
    }
  }

  void _checkSubmissionResult(String currentUrl) {
    // Check for success/failure indicators in the URL
    if (currentUrl.contains('success') || 
        currentUrl.contains('thank') || 
        currentUrl.contains('merci')) {
      _recordSubmissionResult('Success');
    } else if (currentUrl.contains('error') || 
               currentUrl.contains('fail') || 
               currentUrl.contains('erreur')) {
      _recordSubmissionResult('Fail');
    }
    
    // Also check page content for success/failure messages
    _checkPageContent();
  }

  Future<void> _checkPageContent() async {
    if (_webViewController == null) return;

    try {
      // JavaScript to check for success/failure messages in the page content
      final jsCode = '''
        (function() {
          var bodyText = document.body.innerText.toLowerCase();
          
          // Success indicators
          if (bodyText.includes('thank you') || 
              bodyText.includes('success') ||
              bodyText.includes('merci') ||
              bodyText.includes('succès') ||
              bodyText.includes('votre demande a été') ||
              bodyText.includes('request submitted')) {
            return 'Success';
          }
          
          // Failure indicators
          if (bodyText.includes('error') ||
              bodyText.includes('failed') ||
              bodyText.includes('erreur') ||
              bodyText.includes('échec') ||
              bodyText.includes('something went wrong')) {
            return 'Fail';
          }
          
          return 'Unknown';
        })();
      ''';

      final result = await _webViewController!.evaluateJavascript(source: jsCode);
      
      if (result == 'Success' || result == 'Fail') {
        _recordSubmissionResult(result);
      }
    } catch (e) {
      print('Error checking page content: $e');
    }
  }

  void _recordSubmissionResult(String status) {
    // Add ticket to history
    Provider.of<HistoryProvider>(context, listen: false)
        .addTicket(widget.userData.realEstateProject, status);
    
    // Show result dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              status == 'Success' ? Icons.check_circle : Icons.error_outline,
              color: status == 'Success' ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Text(status == 'Success' ? 'Success!' : 'Failed'),
          ],
        ),
        content: Text(
          status == 'Success'
              ? 'Your request has been submitted successfully!'
              : 'There was an issue with your request. Please try again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close webview
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}