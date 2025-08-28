import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nfitness/services/efitness_service.dart';

class InstallmentsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> installments;
  final int? clubId;
  final Future<void> Function()? onRefresh;

  const InstallmentsWidget({
    super.key,
    required this.installments,
    this.clubId,
    this.onRefresh,
  });

  Future<void> _payInstallment(
    BuildContext context,
    int clubId,
    int installmentId,
  ) async {
    final serviceImport = await Future.delayed(
      Duration.zero,
      () => importService(),
    );
    final service = serviceImport();
    final result = await service.payInstallments(
      clubId: clubId,
      installmentIds: [installmentId],
    );
    if (result != null && result['creditCardResponseCode'] == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment successful!')));
      if (onRefresh != null) await onRefresh!();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment failed.')));
    }
  }

  Future<Function> importService() async {
    return EfitnessService().getInstallments;
  }

  @override
  Widget build(BuildContext context) {
    if (installments.isEmpty) {
      return const Center(child: Text('No installments found.'));
    }

    final now = DateTime.now();

    // Sort installments by installmentId ascending
    // Warning, this will not work if:
    // - you missed a payment
    // - you paid an installment out of order
    // - you paid the latest installment, while still having an older unpaid one
    final sortedInstallments = List<Map<String, dynamic>>.from(installments)
      ..sort((a, b) {
        final bId = a['installmentId'] ?? 0;
        final aId = b['installmentId'] ?? 0;
        return aId.compareTo(bId);
      });

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedInstallments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = sortedInstallments[index];
        final from = item['from'];
        final to = item['to'];
        final deadline = item['deadline'];
        final desc = item['description'] ?? '';
        final price = item['price'];
        final paid = item['paid'] == true;
        final frozen = item['frozen'] == true;
        final isProcessing = item['isProcessing'] == true;
        final installmentId = item['installmentId'];

        String formatDate(String? date) {
          if (date == null) return '';
          try {
            final dt = DateTime.parse(date);
            return DateFormat('yyyy-MM-dd').format(dt);
          } catch (_) {
            return date;
          }
        }

        // Determine status text and color
        String statusText;
        Color statusColor;
        bool canPay = false;
        if (paid) {
          statusText = 'Paid';
          statusColor = Colors.green;
        } else {
          DateTime? deadlineDate;
          try {
            deadlineDate = deadline != null ? DateTime.parse(deadline) : null;
          } catch (_) {}
          if (deadlineDate != null && deadlineDate.isAfter(now)) {
            statusText = 'Upcoming';
            statusColor = Colors.orange;
            canPay = true;
          } else {
            statusText = 'Unpaid';
            statusColor = Colors.red;
            canPay = true;
          }
        }

        return Card(
          child: ListTile(
            leading: Icon(
              paid
                  ? Icons.check_circle
                  : frozen
                  ? Icons.ac_unit
                  : Icons.radio_button_unchecked,
              color: paid
                  ? Colors.green
                  : frozen
                  ? Colors.blue
                  : Colors.orange,
            ),
            title: Text(
              desc,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('From: ${formatDate(from)}  To: ${formatDate(to)}'),
                Text('Deadline: ${formatDate(deadline)}'),
                if (isProcessing)
                  const Text(
                    'Processing...',
                    style: TextStyle(color: Colors.blue),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canPay &&
                        !paid &&
                        clubId != null &&
                        installmentId != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).cardColor.withValues(alpha: 0.6),
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onSurface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                          ),
                          onPressed: () =>
                              _payInstallment(context, clubId!, installmentId),
                          child: const Text('Pay'),
                        ),
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${price?.toStringAsFixed(2) ?? '-'} zł',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(statusText, style: TextStyle(color: statusColor)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
