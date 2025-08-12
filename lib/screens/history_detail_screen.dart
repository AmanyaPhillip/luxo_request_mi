import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/models.dart';

class HistoryDetailScreen extends StatelessWidget {
  final Ticket ticket;

  const HistoryDetailScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final data = ticket.submittedData;
    final isSuccess = ticket.status == 'Success';
    final statusColor = isSuccess ? Colors.green : Colors.red;
    final statusIcon = isSuccess ? Icons.check_circle : Icons.error_outline;
    final hasScreenshot = data.imagePath != null && 
                          data.imagePath!.isNotEmpty && 
                          File(data.imagePath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        centerTitle: true,
        actions: [
          if (hasScreenshot)
            IconButton(
              icon: const Icon(Icons.fullscreen),
              onPressed: () => _showFullscreenImage(context, data.imagePath!),
              tooltip: 'View Fullscreen',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Date Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 32),
                        const SizedBox(width: 12),
                        Text(
                          'Status: ${ticket.status}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Submitted on: ${DateFormat.yMMMd().add_jm().format(ticket.requestDate)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Screenshot or Submitted Data
            if (hasScreenshot) ...[
              // Screenshot Display
              Text(
                'Submission Screenshot',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: () => _showFullscreenImage(context, data.imagePath!),
                      child: Container(
                        constraints: const BoxConstraints(
                          maxHeight: 600,
                        ),
                        child: Image.file(
                          File(data.imagePath!),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Screenshot not available'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                      child: Row(
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tap to view fullscreen',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Project Summary
              Text(
                'Project Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildSummaryRow(context, Icons.person, 'Name', '${data.firstName} ${data.lastName}'),
                      const SizedBox(height: 12),
                      _buildSummaryRow(context, Icons.business, 'Project', data.realEstateProject),
                      const SizedBox(height: 12),
                      _buildSummaryRow(context, Icons.home, 'Unit', data.unit),
                      const SizedBox(height: 12),
                      _buildSummaryRow(context, Icons.language, 'Language', data.language),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Fallback to traditional data display if no screenshot
              Text(
                'Submitted Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildInfoRow(context, Icons.person_outline, 'Title', data.title),
                      _buildInfoRow(context, Icons.person, 'First Name', data.firstName),
                      _buildInfoRow(context, Icons.person, 'Last Name', data.lastName),
                      _buildInfoRow(context, Icons.phone, 'Phone', data.phone),
                      _buildInfoRow(context, Icons.email, 'Email', data.email),
                      _buildInfoRow(context, Icons.business, 'Project', data.realEstateProject),
                      _buildInfoRow(context, Icons.home, 'Unit', data.unit),
                      _buildInfoRow(context, Icons.language, 'Language', data.language),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullscreenImageViewer(imagePath: imagePath),
      ),
    );
  }
}

class _FullscreenImageViewer extends StatelessWidget {
  final String imagePath;

  const _FullscreenImageViewer({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Screenshot not available',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The screenshot file could not be loaded',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}