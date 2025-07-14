import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/print_debug.dart';

class MaterialEstimationDialog extends StatefulWidget {
  final String selectedProjectLocationName;
  final String selectedProjectName;
  final String workName;
  final String costCategory;
  final String materialName;

  const MaterialEstimationDialog({
    super.key,
    required this.selectedProjectLocationName,
    required this.selectedProjectName,
    required this.workName,
    required this.costCategory,
    required this.materialName,
  });

  @override
  MaterialEstimationDialogState createState() => MaterialEstimationDialogState();
}

class MaterialEstimationDialogState extends State<MaterialEstimationDialog> {
  bool _isLoading = false;
  double _requestedTotalAmount = 0.0;
  double _reqDisc = 0.0;
  double _totalEstimateAmount = 0.0;
  double _totalEstimateQty = 0.0;
  double _totalRqQty = 0.0;

  int touchedIndex = -1;




  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      //methoord
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String reqUrl = '${APIHost().apiURL}/project_payment_controller.php/EstimateMaterialCost';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          "location_name": widget.selectedProjectLocationName,
          "project_name": widget.selectedProjectName,
          "work_name": widget.workName,
          "cost_category": widget.costCategory,
          "material_name": widget.materialName,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        if (responseData['status'] == 200) {
          if (responseData['estimateData'] is List && responseData['estimateData'].isNotEmpty) {
            final estimationData = responseData['estimateData'][0];
            if (responseData['requestdData'] is List &&
                responseData['requestdData'].isNotEmpty &&
                responseData['requestdData'][0] is List &&
                responseData['requestdData'][0].isNotEmpty) {
              final requestData = responseData['requestdData'][0][0];
              setState(() {
                _requestedTotalAmount = num.tryParse(requestData['request_amount'].toString())?.toDouble() ?? 0.0;
                _totalEstimateAmount = num.tryParse(estimationData['total_estimate_amount'].toString())?.toDouble() ?? 0.0;
                _totalEstimateQty = num.tryParse(estimationData['total_estimate_qty'].toString())?.toDouble() ?? 0.0;
                _totalRqQty = num.tryParse(requestData['requested_qty'].toString())?.toDouble() ?? 0.0;
                _reqDisc = num.tryParse(requestData['item_disc'].toString())?.toDouble() ?? 0.0;

              });
            } else {
              _showError('No request data found.');
            }
          } else {
            _showError('No material data found.');
          }
        } else {
          final String message = responseData['message'] ?? 'Unknown Error';
          _showError(message);
        }
      } else {
        _showError('HTTP Error: ${response.statusCode}');
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'material_budgeted_cost.dart');
      _showError('Exception: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600 ? 100 : 20,
        vertical: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 10,
      backgroundColor: Colors.white,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width > 600 ? 600 : double.infinity,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient background
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(
                  'Material Budgeted Cost',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width > 600 ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Content area
              Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoading
                    ? _buildLoadingIndicator()
                    : _buildContent(),
              ),

              // Footer with close button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading material estimation...',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary information
        _buildInfoRow('Project Location:', widget.selectedProjectLocationName),
        _buildInfoRow('Project Name:', widget.selectedProjectName),
        if (widget.workName != null) _buildInfoRow('Work Name:', widget.workName!),
        if (widget.costCategory != null) _buildInfoRow('Cost Category:', widget.costCategory!),
        if (widget.materialName != null) _buildInfoRow('Material Name:', widget.materialName!),

        const SizedBox(height: 16),
        Divider(color: Colors.grey.shade300),
        const SizedBox(height: 16),

        // Pie chart section
        Center(child: _buildPieChart()),

        const SizedBox(height: 16),
        Divider(color: Colors.grey.shade300),
        const SizedBox(height: 16),
        _buildNumberRow('Estimated Qty:', _totalEstimateQty),
        _buildNumberRow('Requested Qty:', _totalRqQty),
        _buildNumberRow('Budgeted Amount:', _totalEstimateAmount, isCurrency: true),
        _buildNumberRow('Requested Amount:', _requestedTotalAmount, isCurrency: true),
        if(_reqDisc>0)...[
          _buildNumberRow('Discount Amount:', _reqDisc, isCurrency: true),
        ]
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberRow(String label, double value, {bool isCurrency = false}) {
    final formatter = NumberFormat('#,###.00', 'en_US');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isCurrency ? '${formatter.format(value)} LKR' : formatter.format(value),
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    if (_totalEstimateAmount <= 0) return const SizedBox();

    double usedAmount = _requestedTotalAmount-_reqDisc;
    double remainingAmount = (_totalEstimateAmount - usedAmount).clamp(0, _totalEstimateAmount);
    double exceededAmount = (usedAmount > _totalEstimateAmount) ? (usedAmount - _totalEstimateAmount) : 0;

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pie Chart
          SizedBox(
            width: MediaQuery.of(context).size.width > 600 ? 200 : 150,
            height: MediaQuery.of(context).size.width > 600 ? 200 : 150,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions || pieTouchResponse?.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 0,
                centerSpaceRadius: MediaQuery.of(context).size.width > 600 ? 20 : 10,
                sections: [
                  // Used Amount (Requested)
                  PieChartSectionData(
                    color: Colors.blue,
                    value: (exceededAmount > 0) ? _totalEstimateAmount : usedAmount,
                    title: '${_getPercentage((exceededAmount > 0) ? _totalEstimateAmount : usedAmount, _totalEstimateAmount)}%',
                    radius: touchedIndex == 0 ? (MediaQuery.of(context).size.width > 600 ? 70.0 : 60.0) : (MediaQuery.of(context).size.width > 600 ? 65.0 : 55.0),
                    titleStyle: TextStyle(
                      fontSize: touchedIndex == 0 ? (MediaQuery.of(context).size.width > 600 ? 16.0 : 14.0) : (MediaQuery.of(context).size.width > 600 ? 14.0 : 12.0),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  // Exceeded Amount (If Used > Estimated)
                  if (exceededAmount > 0)
                    PieChartSectionData(
                      color: Colors.red,
                      value: exceededAmount,
                      title: '${_getPercentage(exceededAmount, _totalEstimateAmount)}%',
                      radius: touchedIndex == 1 ? (MediaQuery.of(context).size.width > 600 ? 70.0 : 60.0) : (MediaQuery.of(context).size.width > 600 ? 65.0 : 55.0),
                      titleStyle: TextStyle(
                        fontSize: touchedIndex == 1 ? (MediaQuery.of(context).size.width > 600 ? 16.0 : 14.0) : (MediaQuery.of(context).size.width > 600 ? 14.0 : 12.0),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  // Remaining Amount
                  if (exceededAmount == 0 && remainingAmount > 0)
                    PieChartSectionData(
                      color: Colors.grey.shade400,
                      value: remainingAmount,
                      title: '${_getPercentage(remainingAmount, _totalEstimateAmount)}%',
                      radius: touchedIndex == 2 ? (MediaQuery.of(context).size.width > 600 ? 70.0 : 60.0) : (MediaQuery.of(context).size.width > 600 ? 65.0 : 55.0),
                      titleStyle: TextStyle(
                        fontSize: touchedIndex == 2 ? (MediaQuery.of(context).size.width > 600 ? 16.0 : 14.0) : (MediaQuery.of(context).size.width > 600 ? 14.0 : 12.0),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Legend
          Column(
            children: [
              _buildLegendItem(Colors.green, "Estimated", _totalEstimateAmount, _totalEstimateAmount),
              _buildLegendItem(Colors.blue, "Used", usedAmount, _totalEstimateAmount),
              _buildLegendItem(
                exceededAmount > 0 ? Colors.red : Colors.grey.shade400,
                exceededAmount > 0 ? "Exceeded" : "Balance",
                exceededAmount > 0 ? exceededAmount : remainingAmount,
                _totalEstimateAmount,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, double value, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width > 600 ? 14 : 10,
            height: MediaQuery.of(context).size.width > 600 ? 14 : 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$label: ${NumberFormat('#,###.00', 'en_US').format(double.tryParse(value.toString()) ?? 0)} LKR (${_getPercentage(value, total)}%)',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getPercentage(double value, double total) {
    if (total == 0) return "0";
    return (value / total * 100).toStringAsFixed(1);
  }
}

// Helper function to show the dialog
void showMaterialEstimationDialog({
  required BuildContext context,
  required String selectedProjectLocationName,
  required String selectedProjectName,
  String? workName,
  String? costCategory,
  String? materialName,
}) {
  showDialog(
    context: context,
    builder: (context) => MaterialEstimationDialog(
      selectedProjectLocationName: selectedProjectLocationName,
      selectedProjectName: selectedProjectName,
      workName: workName.toString(),
      costCategory: costCategory.toString(),
      materialName: materialName.toString(),
    ),
  );
}