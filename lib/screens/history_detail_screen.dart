import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        centerTitle: true,
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

            // Submitted Data Card
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
        ),
      ),
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
}