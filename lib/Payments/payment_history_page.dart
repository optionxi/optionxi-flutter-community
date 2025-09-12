import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/Payments/payment_history_model.dart';
import 'package:optionxi/Payments/subscription_model.dart';
import 'package:optionxi/Payments/subscription_provider.dart';

class PaymentHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the existing controller instance
    final SubscriptionController subscriptionController =
        Get.find<SubscriptionController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment History'),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.download),
        //     onPressed: () => _exportPaymentHistory(context),
        //   ),
        // ],
      ),
      body: Obx(() {
        final paymentHistory = subscriptionController.paymentHistory;

        if (paymentHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No payment history',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
                Text('Your subscription payments will appear here'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: paymentHistory.length,
          itemBuilder: (context, index) {
            final payment = paymentHistory[index];
            return _buildPaymentTile(context, payment);
          },
        );
      }),
    );
  }

  Widget _buildPaymentTile(BuildContext context, PaymentHistory payment) {
    final planName = SubscriptionPlan.getPlans()
        .firstWhere((plan) => plan.id == payment.planId,
            orElse: () => SubscriptionPlan.getPlans().first)
        .name;

    Color statusColor;
    IconData statusIcon;

    switch (payment.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text('$planName Plan'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction ID: ${payment.transactionId}'),
            Text('Date: ${payment.date.toString().split(' ')[0]}'),
            Text(
              'Status: ${payment.status.toUpperCase()}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${payment.amount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (payment.status == 'completed')
              Icon(Icons.receipt, size: 16, color: Colors.grey),
          ],
        ),
        onTap: () => _showPaymentDetails(context, payment, planName),
      ),
    );
  }

  void _showPaymentDetails(
      BuildContext context, PaymentHistory payment, String planName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Plan', planName),
              _buildDetailRow(
                  'Amount', '₹${payment.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Date', payment.date.toString().split(' ')[0]),
              _buildDetailRow(
                  'Time', payment.date.toString().split(' ')[1].split('.')[0]),
              _buildDetailRow('Transaction ID', payment.transactionId),
              _buildDetailRow('Status', payment.status.toUpperCase()),
              _buildDetailRow('Payment ID', payment.id),
            ],
          ),
        ),
        actions: [
          if (payment.status == 'completed')
            // TextButton(
            //   onPressed: () => _downloadReceipt(context, payment),
            //   child: Text('Download Receipt'),
            // ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }
}
