import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:roky_holding/env/api_info.dart';
import 'package:roky_holding/env/number_format.dart';
import '../env/print_debug.dart';

class EstimationRequestSummary {
  final String costCategory;
  final String estimatedAmount;
  final int totalRequests;
  final String allRequestsTotal;
  final String remainingEstimateBalance;
  final String currentRequestTotal;
  final String oldRequestAmount;
  EstimationRequestSummary({
    required this.costCategory,
    required this.estimatedAmount,
    required this.totalRequests,
    required this.allRequestsTotal,
    required this.remainingEstimateBalance,
    required this.currentRequestTotal,
    required this.oldRequestAmount,
  });

  factory EstimationRequestSummary.fromJson(Map<String, dynamic> json) {
    return EstimationRequestSummary(
      costCategory: json['cost_category'] ?? "NA",
      estimatedAmount: json['estimated_amount'] ?? "0",
      totalRequests: json['total_requests'] ?? 0,
      allRequestsTotal: json['all_requests_total'] ?? "0",
      remainingEstimateBalance: json['remaining_estimate_balance'] ?? "0",
      currentRequestTotal: json['current_request_total'] ?? "0",
      oldRequestAmount: '0'
    );
  }
}

Future<List<EstimationRequestSummary>> fetchEstimationRequestSummary(int requestId) async {
  final String reqUrl='${APIHost().apiURL}/project_payment_controller.php/ViewEstimationCategory';
  PD.pd(text: reqUrl);
  PD.pd(text: reqUrl.toString());
  final response = await http.post(
    Uri.parse(reqUrl),
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "Authorization": APIToken().token,
      "request_id": requestId,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    PD.pd(text: data.toString());
    if (data['status'] == 200) {
      return (data['data'] as List)
          .map((item) => EstimationRequestSummary.fromJson(item))
          .toList();
    } else {
      throw Exception('API Error: ${data['message']}');
    }
  } else {
    throw Exception('HTTP Error: ${response.statusCode}');
  }
}

List<EstimationRequestSummary> _summarizeByCategory(List<EstimationRequestSummary> data) {
  final summarizedData = <EstimationRequestSummary>[];
  final categories = data.map((e) => e.costCategory).toSet();

  for (var category in categories) {
    final categoryItems = data.where((item) => item.costCategory == category).toList();

    // Calculate totals for the category
    double totalEstimated = 0;
    double totalRequested = 0;
    double totalRemaining = 0;
    double thisRequestTotal = 0;
    double oldRequestTotal = 0;
    int totalRequests = 0;

    for (var item in categoryItems) {
      totalEstimated += double.tryParse(item.estimatedAmount) ?? 0;
      totalRequested += double.tryParse(item.allRequestsTotal) ?? 0;
      totalRemaining += double.tryParse(item.remainingEstimateBalance) ?? 0;
      thisRequestTotal += double.tryParse(item.currentRequestTotal) ?? 0;
      totalRequests += item.totalRequests;

    }
    oldRequestTotal= totalRequested-thisRequestTotal;
    // Add only the summary row
    summarizedData.add(EstimationRequestSummary(
      costCategory: category,
      estimatedAmount: totalEstimated.toStringAsFixed(2),
      totalRequests: totalRequests,
      allRequestsTotal: totalRequested.toStringAsFixed(2),
      remainingEstimateBalance: totalRemaining.toStringAsFixed(2),
      currentRequestTotal: thisRequestTotal.toString(),
      oldRequestAmount: oldRequestTotal.toString(),
    ));
  }

  return summarizedData;
}

Future<void> showEstimationVsRequestDialog(BuildContext context, List<EstimationRequestSummary> data) {
  final summarizedData = _summarizeByCategory(data);
  return showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 700, maxHeight: 600),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Estimation Summary",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey.shade700),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),
                    Expanded(
                      child: summarizedData.isEmpty
                          ? Center(
                        child: Text(
                          "No records found.",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      )
                          : ListView.separated(
                        itemCount: summarizedData.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final item = summarizedData[index];
                          final isNegative = item.remainingEstimateBalance.startsWith('-');

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blueGrey.shade200, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.category,
                                      color: Colors.blueGrey.shade800,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.costCategory,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.stacked_bar_chart,
                                      color: Colors.teal.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text("Estimated Amount: ", style: TextStyle(fontWeight: FontWeight.w500)),
                                    Text(
                                      NumberStyles.currencyStyle(item.estimatedAmount),
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.stacked_bar_chart,
                                      color: Colors.teal.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text("Current Request Amount: ", style: TextStyle(fontWeight: FontWeight.w500)),
                                    Text(
                                      NumberStyles.currencyStyle(item.currentRequestTotal),
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.receipt_long,
                                      color: Colors.orange.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text("Preview Request Amount: ", style: TextStyle(fontWeight: FontWeight.w500)),
                                    Text(
                                      NumberStyles.currencyStyle(item.oldRequestAmount),
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.format_list_numbered,
                                      color: Colors.indigo,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text("Total Requests: ", style: TextStyle(fontWeight: FontWeight.w500)),
                                    Text(
                                      item.totalRequests.toString(),
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.balance,
                                      color: isNegative ? Colors.red : Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text("Remaining Balance: ", style: TextStyle(fontWeight: FontWeight.w500)),
                                    Text(
                                      NumberStyles.currencyStyle(item.remainingEstimateBalance),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isNegative ? Colors.red : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),

                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.close),
                        label: Text("Close"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}