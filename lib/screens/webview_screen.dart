import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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
  bool _showingSuccessCountdown = false;
  int _countdownSeconds = 7;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation during success countdown
        return !_showingSuccessCountdown;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Submit Request'),
          leading: _showingSuccessCountdown 
              ? null 
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
          actions: _showingSuccessCountdown 
              ? null 
              : [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _handleFileUpload,
                    tooltip: 'Upload File',
                  ),
                ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if (_isLoading && !_showingSuccessCountdown)
                  LinearProgressIndicator(
                    value: _loadingProgress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                if (_uploadedFilePath != null && !_showingSuccessCountdown)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.green.withOpacity(0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'File uploaded: ${_uploadedFilePath!.split('/').last}',
                            style: const TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            setState(() {
                              _uploadedFilePath = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                    },
                    onLoadStart: (controller, url) {
                      if (!_showingSuccessCountdown) {
                        setState(() {
                          _isLoading = true;
                          _loadingProgress = 0;
                        });
                      }
                    },
                    onProgressChanged: (controller, progress) {
                      if (!_showingSuccessCountdown) {
                        setState(() {
                          _loadingProgress = progress / 100;
                        });
                      }
                    },
                    onLoadStop: (controller, url) async {
                      if (!_showingSuccessCountdown) {
                        setState(() {
                          _isLoading = false;
                        });
                        if (_isInitialLoad) {
                          await _populateFormFields();
                          setState(() {
                            _isInitialLoad = false;
                          });
                        }
                        // Check for success message in page content
                        await _checkPageForSuccess();
                      }
                    },
                    onUpdateVisitedHistory: (controller, url, isReload) {
                      if (!_isInitialLoad && url.toString() != widget.url && !_showingSuccessCountdown) {
                        _checkSubmissionResult(url?.toString() ?? '');
                      }
                    },
                    onPermissionRequest: (controller, request) async {
                      return PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.GRANT,
                      );
                    },
                    initialSettings: InAppWebViewSettings(
                      useShouldOverrideUrlLoading: true,
                      mediaPlaybackRequiresUserGesture: false,
                      allowsInlineMediaPlayback : true,
                      javaScriptEnabled: true,
                      domStorageEnabled: true,
                      allowFileAccessFromFileURLs: true,
                      allowUniversalAccessFromFileURLs: true,
                    ),
                  ),
                ),
              ],
            ),
            
            // Success countdown overlay
            if (_showingSuccessCountdown)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.all(32),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Request Submitted Successfully!',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Returning to main screen in $_countdownSeconds seconds...',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: Stack(
                              children: [
                                CircularProgressIndicator(
                                  value: (7 - _countdownSeconds) / 7,
                                  strokeWidth: 4,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    '$_countdownSeconds',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _showingSuccessCountdown ? null : Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_uploadedFilePath == null)
                ElevatedButton.icon(
                  onPressed: _handleFileUpload,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload File'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Form will be automatically populated. Please review and submit.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkPageForSuccess() async {
    if (_webViewController == null || _submissionRecorded) return;
    
    final jsCode = '''
      (function() {
        var bodyText = document.body.innerText.toLowerCase();
        var successIndicators = [
          'request submitted successfully',
          'demande soumise avec succès',
          'thank you',
          'merci',
          'success',
          'succès',
          'submitted',
          'soumis'
        ];
        
        for (var i = 0; i < successIndicators.length; i++) {
          if (bodyText.includes(successIndicators[i])) {
            return true;
          }
        }
        return false;
      })();
    ''';

    try {
      final result = await _webViewController!.evaluateJavascript(source: jsCode);
      if (result == true) {
        await _handleSuccessfulSubmission();
      }
    } catch (e) {
      debugPrint('Error checking page content: $e');
    }
  }

  Future<void> _handleSuccessfulSubmission() async {
    if (_submissionRecorded) return;
    
    _submissionRecorded = true;
    
    // Capture screenshot
    String? screenshotPath;
    try {
      screenshotPath = await _captureScreenshot();
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
    }
    
    // Get submitted data
    final submittedData = await _getSubmittedDataFromForm();
    
    // Update the data with screenshot path
    final updatedData = UserData(
      title: submittedData.title,
      firstName: submittedData.firstName,
      lastName: submittedData.lastName,
      phone: submittedData.phone,
      email: submittedData.email,
      realEstateProject: submittedData.realEstateProject,
      unit: submittedData.unit,
      language: submittedData.language,
      imagePath: screenshotPath,
    );
    
    // Add to history
    if (mounted) {
      Provider.of<HistoryProvider>(context, listen: false)
          .addTicket('Success', updatedData);
    }
    
    // Show success countdown
    setState(() {
      _showingSuccessCountdown = true;
      _countdownSeconds = 7;
    });
    
    _startCountdown();
  }

  Future<String?> _captureScreenshot() async {
    if (_webViewController == null) return null;
    
    try {
      final Uint8List? screenshot = await _webViewController!.takeScreenshot();
      if (screenshot != null) {
        final appDocsDir = await getApplicationDocumentsDirectory();
        final uniqueFileName = 'screenshot_${const Uuid().v4()}.png';
        final file = File('${appDocsDir.path}/$uniqueFileName');
        await file.writeAsBytes(screenshot);
        return file.path;
      }
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
    }
    return null;
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _showingSuccessCountdown) {
        setState(() {
          _countdownSeconds--;
        });
        
        if (_countdownSeconds > 0) {
          _startCountdown();
        } else {
          // Navigate back to main screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    });
  }

  Future<void> _handleFileUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // Check file size (5MB limit)
        if (await file.length() > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File is too large. Please select an image under 5MB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Save file to app directory
        final appDocsDir = await getApplicationDocumentsDirectory();
        final uniqueFileName = '${const Uuid().v4()}.jpg';
        final savedFile = await file.copy('${appDocsDir.path}/$uniqueFileName');

        setState(() {
          _uploadedFilePath = savedFile.path;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File uploaded: ${result.files.single.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Try to inject the file into the web form if there's a file input
        await _injectFileIntoForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _injectFileIntoForm() async {
    if (_webViewController == null || _uploadedFilePath == null) return;

    // This is a basic attempt to interact with file inputs
    // Note: Due to browser security restrictions, directly setting file inputs is limited
    final jsCode = '''
      (function() {
        try {
          var fileInputs = document.querySelectorAll('input[type="file"]');
          if (fileInputs.length > 0) {
            // Create a visual indicator that a file has been selected
            fileInputs.forEach(function(input) {
              var label = document.createElement('span');
              label.style.color = 'green';
              label.style.fontSize = '12px';
              label.style.marginLeft = '10px';
              label.textContent = 'File ready for upload';
              
              // Remove existing labels
              var existingLabels = input.parentNode.querySelectorAll('span[style*="color: green"]');
              existingLabels.forEach(function(el) { el.remove(); });
              
              input.parentNode.appendChild(label);
            });
            return "File indicator added";
          }
          return "No file inputs found";
        } catch (error) {
          return "Error: " + error.message;
        }
      })();
    ''';

    try {
      await _webViewController!.evaluateJavascript(source: jsCode);
    } catch (e) {
      debugPrint('Error injecting file indicator: $e');
    }
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
    
    try {
      await _webViewController!.evaluateJavascript(source: jsCode);
    } catch (e) {
      debugPrint('Error populating form: $e');
    }
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
      _handleSuccessfulSubmission();
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
                Icons.error_outline,
                color: Colors.red,
              ),
              const SizedBox(width: 12),
              const Text('Failed'),
            ],
          ),
          content: const Text(
            'There was an issue with your request. Please try again.',
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