import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:roky_holding/env/api_info.dart';
import 'package:roky_holding/env/app_logs_to.dart';
import 'package:roky_holding/env/number_format.dart';
import '../env/print_debug.dart';


class PaymentRequestData {
  final String projectName;
  final String tender;
  final String clientName;
  final String startDate;
  final String endDate;
  final String locationName;
  final int requestId;
  final String requestDate;
  final double requestedAmount;
  final int statusId;
  final String? paymentRef;
  final String? paidDate;
  final String workName;
  final String costCategory;
  final double categoryBudget;
  final double previousRequestsTotal;
  final double currentRequestAmount;
  final double remainingBudget;
  final double totalProjectEstimated;
  final double totalSpentAmountPreviewAll;
  final double itemDiscount;
  PaymentRequestData({
    required this.projectName,
    required this.tender,
    required this.clientName,
    required this.startDate,
    required this.endDate,
    required this.locationName,
    required this.requestId,
    required this.requestDate,
    required this.requestedAmount,
    required this.statusId,
    this.paymentRef,
    this.paidDate,
    required this.workName,
    required this.costCategory,
    required this.categoryBudget,
    required this.previousRequestsTotal,
    required this.currentRequestAmount,
    required this.remainingBudget,
    required this.totalProjectEstimated,
    required this.totalSpentAmountPreviewAll,
    required this.itemDiscount
  });

  factory PaymentRequestData.fromJson(Map<String, dynamic> json) {
    return PaymentRequestData(
      projectName: json['project_name'] ?? '',
      tender: json['tender'] ?? '',
      clientName: json['client_name'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      locationName: json['location_name'] ?? '',
      requestId: json['tbl_user_payment_request_id'] ?? 0,
      requestDate: json['request_date'] ?? '',
      requestedAmount: _parseDouble(json['requested_amount']),
      statusId: json['status_id'] ?? 0,
      paymentRef: json['payment_ref'],
      paidDate: json['payed_date'], // Note: API uses 'payed_date' but we'll store as 'paidDate'
      workName: json['work_name'] ?? '',
      costCategory: json['cost_category'] ?? '',
      categoryBudget: _parseDouble(json['category_budget']),
      previousRequestsTotal: _parseDouble(json['previous_requests_total']),
      currentRequestAmount: _parseDouble(json['current_request_amount']),
      remainingBudget: _parseDouble(json['remaining_budget']),
      totalProjectEstimated: _parseDouble(json['totalProjectEstimated']),
      totalSpentAmountPreviewAll: _parseDouble(json['totalSpentAmountPreviewAll']),
      itemDiscount: _parseDouble(json['itemDiscount']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class EstimationDetailsDialog extends StatefulWidget {
  final String projectName;
  final String locationName;
  final int requestId;
  const EstimationDetailsDialog({
    super.key,
    required this.projectName,
    required this.locationName,
    required  this.requestId
  });

  @override
  State<EstimationDetailsDialog> createState() => _EstimationDetailsDialogState();
}

class _EstimationDetailsDialogState extends State<EstimationDetailsDialog> {
  late Map<String, List<PaymentRequestData>> _groupedItems;
  final Map<String, bool> _expandedCategories = {};
  late Map<String, _CategorySummary> _categorySummaries;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    String proj  =widget.projectName;
    String loc= widget.locationName;
    _fetchEstimationData(proj,loc);
  }
  final double totalProjectEstimated=0;

  Future<void> _fetchEstimationData(String projectName,String location) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      String apiURL = '${APIHost().apiURL}/report_controller.php/RequestWiseItems';
      PD.pd(text: apiURL);
      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          'project_name': projectName,
          "location_name":location ,
          "request_id":widget.requestId
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          PD.pd(text: responseData.toString());
          _processData(responseData);
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Failed to load data';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load data: ${response.statusCode}';
        });
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'estimation_category_wise_consume_list.dart');
      setState(() {
        _errorMessage = 'Error fetching data: ${e.toString()}';
      });
      PD.pd(text: 'EstimationDetailsDialog Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _processData(Map<String, dynamic> responseData) {
    _groupedItems = {};
    final List<dynamic> data = responseData['data'] ?? [];

    for (var item in data) {
      final estimationItem = PaymentRequestData .fromJson(item);
      final category = estimationItem.workName;
      _groupedItems.putIfAbsent(category, () => []);
      _groupedItems[category]!.add(estimationItem);
      _expandedCategories[category] = _expandedCategories[category] ?? false;
    }

    // Calculate category summaries
    _categorySummaries = _calculateCategorySummaries();
  }

  Map<String, _CategorySummary> _calculateCategorySummaries() {
    final summaries = <String, _CategorySummary>{};

    _groupedItems.forEach((category, items) {
      double categoryBuget = 0;
      double previewsSpent = 0;
      double curretntSpent = 0;
      double reminingBalance = 0;
      double itemDiscount=0;
      for (var item in items) {
        categoryBuget += item.categoryBudget;
        previewsSpent += item.previousRequestsTotal;
        curretntSpent += item.currentRequestAmount;
        reminingBalance += item.remainingBudget;
        itemDiscount+= item.itemDiscount;
      }

      summaries[category] = _CategorySummary(
          categoryBuget:categoryBuget,
          previewsSpent: previewsSpent,
          curretntSpent: curretntSpent,
          reminingBalance:reminingBalance,
          itemDiscount:itemDiscount
      );
    });

    return summaries;
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 8 : 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile
              ? MediaQuery.of(context).size.width * 0.98
              : MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '${widget.projectName} Estimation',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Text(
                widget.locationName,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage.isNotEmpty)
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _errorMessage,
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: _buildCategorySections(isMobile),
                  ),
                ),
              const SizedBox(height: 16),
              if (!_isLoading && _errorMessage.isEmpty)
                _buildGrandTotal(
                  totalEstimated: _groupedItems.values.first.first.totalProjectEstimated,
                  totalSpent: _groupedItems.values.first.first.totalSpentAmountPreviewAll,
                  isMobile: isMobile,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategorySections(bool isMobile) {
    return _groupedItems.entries.map((entry) {
      final category = entry.key;
      final items = entry.value;
      final summary = _categorySummaries[category]!;

      return Card(
        margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(
          key: Key(category),
          initiallyExpanded: _expandedCategories[category] ?? false,
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedCategories[category] = expanded;
            });
          },
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.category, size: 20),
          ),
          title: Text(
            category,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 16,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: isMobile
              ? Icon(_expandedCategories[category]!
              ? Icons.expand_less
              : Icons.expand_more)
              : _buildSummaryChips(summary, isMobile),
          children: [
            const Divider(height: 1),
            ...items.map((item) => _buildItemTile(item, isMobile)).toList(),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSummaryChips(_CategorySummary summary, bool isMobile) {
    return isMobile
        ? Tooltip(
      message: 'Est: ${NumberStyles.currencyStyle(summary.categoryBuget.toString())}\n'
          'Spent: ${NumberStyles.currencyStyle((summary.curretntSpent+summary.previewsSpent-summary.itemDiscount).toString())}',
      child: Chip(
        backgroundColor: Colors.blue.shade100,
        label: const Icon(Icons.info_outline, size: 16),
      ),
    )
        : Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        Chip(
          backgroundColor: Colors.blue.shade100,
          label: Text(
            'Est: ${NumberStyles.currencyStyle(summary.categoryBuget.toString())}',
            style: TextStyle(fontSize: isMobile ? 10 : 12),
          ),
        ),
        Chip(
          backgroundColor: Colors.orange.shade100,
          label: Text(
            'Spent: ${NumberStyles.currencyStyle((summary.curretntSpent+summary.previewsSpent-summary.itemDiscount).toString())}',
            style: TextStyle(fontSize: isMobile ? 10 : 12),
          ),
        ),
      ],
    );
  }

  Widget _buildItemTile(PaymentRequestData item, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12.0 : 16.0,
        vertical: isMobile ? 8 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  item.costCategory,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: isMobile ? 13 : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isMobile) // Only show chip on desktop
                Chip(
                  label: Text(
                    item.costCategory,
                    style: TextStyle(fontSize: isMobile ? 10 : 12),
                  ),
                  backgroundColor: Colors.green.shade100,
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildProgressBar(item, isMobile),
          const SizedBox(height: 8),
          _buildInfoChips(item, isMobile),
        ],
      ),
    );
  }

  Widget _buildProgressBar(PaymentRequestData item, bool isMobile) {
    final percentage = item.categoryBudget > 0
        ? ((item.currentRequestAmount+item.previousRequestsTotal) / item.categoryBudget).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade300,
          color: percentage > 0.9 ? Colors.orange : Colors.blue,
          minHeight: isMobile ? 4 : 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 4),
        Text(
          '${(percentage * 100).toStringAsFixed(1)}% used',
          style: TextStyle(
            fontSize: isMobile ? 10 : 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChips(PaymentRequestData item, bool isMobile) {
    final chips = [
      _buildInfoChip(
        'Est: ${NumberStyles.currencyStyle(item.categoryBudget.toString())}',
        Colors.blue.shade100,
        isMobile,
      ),
      _buildInfoChip(
        'Spent: ${NumberStyles.currencyStyle((item.currentRequestAmount+item.previousRequestsTotal-item.itemDiscount).toString())}',
        Colors.orange.shade100,
        isMobile,
      ),
      _buildInfoChip(
        'Rem: ${NumberStyles.currencyStyle((item.categoryBudget-item.currentRequestAmount-item.previousRequestsTotal+item.itemDiscount).toString())}',
        item.remainingBudget < 0 ? Colors.red.shade100 : Colors.green.shade100,
        isMobile,
      ),
    ];

    return isMobile
        ? Wrap(
      spacing: 4,
      runSpacing: 4,
      children: chips,
    )
        : SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips,
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color, bool isMobile) {
    return Chip(
      backgroundColor: color,
      label: Text(
        text,
        style: TextStyle(fontSize: isMobile ? 10 : 12),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 4 : 8,
        vertical: isMobile ? 0 : 4,
      ),
    );
  }

  Widget _buildGrandTotal({
    required double totalEstimated,
    required double totalSpent,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Grand Total',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: isMobile ? 18 : null,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          isMobile
              ? Column(
            children: [
              _buildTotalItem(
                'Project Estimated',
                totalEstimated,
                Colors.blue,
                isMobile,
              ),
              const SizedBox(height: 8),
              _buildTotalItem(
                'Payment Approved',
                totalSpent,
                Colors.orange,
                isMobile,
              ),
            ],
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTotalItem(
                'Project Estimated',
                totalEstimated,
                Colors.blue,
                isMobile,
              ),
              _buildTotalItem(
                'Payment Approved',
                totalSpent,
                Colors.orange,
                isMobile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem(
      String label,
      double value,
      Color color,
      bool isMobile,
      ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: isMobile ? 12 : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          NumberStyles.currencyStyle(value.toString()),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontSize: isMobile ? 16 : null,
          ),
        ),
      ],
    );
  }
}




class _CategorySummary {
  final double categoryBuget;
  final double previewsSpent;
  final double curretntSpent;
  final double reminingBalance;
  final double itemDiscount;
  _CategorySummary({
    required this.categoryBuget,
    required this.previewsSpent,
    required this.curretntSpent,
    required this.reminingBalance,
    required this.itemDiscount
  });
}

