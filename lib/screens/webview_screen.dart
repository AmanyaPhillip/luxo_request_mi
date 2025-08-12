import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
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
  bool _isInitialLoad = true;
  bool _submissionRecorded = false;
  String? _uploadedFilePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Request'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          if (_isLoading)
            LinearProgressIndicator(
              value: _loadingProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
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
                if (_isInitialLoad) {
                  await _populateFormFields();
                  setState(() {
                    _isInitialLoad = false;
                  });
                }
              },
              onUpdateVisitedHistory: (controller, url, isReload) {
                if (!_isInitialLoad && url.toString() != widget.url) {
                  _checkSubmissionResult(url?.toString() ?? '');
                }
              },
              onOpenFileChooser: (controller, fileChooserParams) async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );

                if (result != null && result.files.single.path != null) {
                  final file = File(result.files.single.path!);

                  if (await file.length() > 5 * 1024 * 1024) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'File is too large. Please select an image under 5MB.')));
                    }
                    return [];
                  }

                  final appDocsDir =
                      await getApplicationDocumentsDirectory();
                  final uniqueFileName = '${const Uuid().v4()}.jpg';
                  final savedFile = await file
                      .copy('${appDocsDir.path}/$uniqueFileName');

                  setState(() {
                    _uploadedFilePath = savedFile.path;
                  });

                  return [Uri.file(savedFile.path)];
                }
                return [];
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
        child: Text(
          'Form will be automatically populated. Please review and submit.',
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
    final jsCode = '''
      (function() {
        try {
          var salutationField = document.querySelector('select[name="salutation"], #salutation');
          if (salutationField) salutationField.value = "${widget.userData.title == 'Mr.' ? 'Monsieur' : 'Madame'}";
          
          var firstNameField = document.querySelector('input[name="prenom"], #prenom');
          if (firstNameField) firstNameField.value = "${widget.userData.firstName}";

          var lastNameField = document.querySelector('input[name="nom"], #nom');
          if (lastNameField) lastNameField.value = "${widget.userData.lastName}";

          var phoneField = document.querySelector('input[name="telephone"], #telephone');
          if (phoneField) phoneField.value = "${widget.userData.phone}";

          var emailField = document.querySelector('input[name="courriel"], #courriel');
          if (emailField) emailField.value = "${widget.userData.email}";

          var projectField = document.querySelector('select[name="projet"], #projet');
          if (projectField) projectField.value = "${widget.userData.realEstateProject}";

          var unitField = document.querySelector('input[name="unite"], #unite');
          if (unitField) unitField.value = "${widget.userData.unit}";

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
    await _webViewController!.evaluateJavascript(source: jsCode);
  }

  Future<UserData> _getSubmittedDataFromForm() async {
    if (_webViewController == null) return widget.userData;
    final jsCode = '''
    (function() {
      function getValue(selector) {
        var el = document.querySelector(selector);
        return el ? el.value : '';
      }
      return JSON.stringify({
        "title": getValue('select[name="salutation"], #salutation'),
        "firstName": getValue('input[name="prenom"], #prenom'),
        "lastName": getValue('input[name="nom"], #nom'),
        "phone": getValue('input[name="telephone"], #telephone'),
        "email": getValue('input[name="courriel"], #courriel'),
        "realEstateProject": getValue('select[name="projet"], #projet'),
        "unit": getValue('input[name="unite"], #unite'),
        "language": "${widget.userData.language}"
      });
    })();
    ''';

    try {
      final result = await _webViewController!.evaluateJavascript(source: jsCode);
      if (result != null) {
        final Map<String, dynamic> scrapedData = jsonDecode(result);
        if (scrapedData['title'] == 'Monsieur') scrapedData['title'] = 'Mr.';
        if (scrapedData['title'] == 'Madame') scrapedData['title'] = 'Mrs.';
        scrapedData['imagePath'] = _uploadedFilePath;
        return UserData.fromJson(scrapedData);
      }
    } catch (e) {
      debugPrint('Error scraping form data: $e');
    }
    return widget.userData;
  }

  void _checkSubmissionResult(String currentUrl) {
    if (_submissionRecorded) return;
    bool isSuccess = currentUrl.contains('success') ||
        currentUrl.contains('thank') ||
        currentUrl.contains('merci');
    bool isFail = currentUrl.contains('error') ||
        currentUrl.contains('fail') ||
        currentUrl.contains('erreur');
    if (isSuccess) {
      _recordSubmissionResult('Success');
    } else if (isFail) {
      _recordSubmissionResult('Fail');
    }
  }

  void _recordSubmissionResult(String status) async {
    if (_submissionRecorded) return;
    _submissionRecorded = true;
    final submittedData = await _getSubmittedDataFromForm();
    if (mounted) {
      Provider.of<HistoryProvider>(context, listen: false)
          .addTicket(status, submittedData);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                status == 'Success'
                    ? Icons.check_circle
                    : Icons.error_outline,
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
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}