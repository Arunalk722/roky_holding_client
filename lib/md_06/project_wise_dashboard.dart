import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:roky_holding/env/number_format.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../env/DialogBoxs.dart';
import '../env/api_info.dart';
import '../env/app_bar.dart';
import '../env/app_logs_to.dart';
import '../env/multi_selection.dart';
import '../env/print_debug.dart';



class ProjectDashboard extends StatefulWidget {
  const ProjectDashboard({super.key});

  @override
  _ProjectDashboardState createState() => _ProjectDashboardState();
}

class _ProjectDashboardState extends State<ProjectDashboard> {
  final _formKey = GlobalKey<FormBuilderState>();
  final TextEditingController _txtStartDate = TextEditingController();
  final TextEditingController _txtEndDate = TextEditingController();

  List<dynamic> _projectData = [];
  bool _isLoading = false;
  bool _hasData = false;
  final List<Color> chartColors = [
    Colors.blue.shade400,
    Colors.green.shade400,
    Colors.orange.shade400,
    Colors.purple.shade400,
    Colors.red.shade400,
    Colors.teal.shade400,
    Colors.pink.shade400,
    Colors.indigo.shade400,
    Colors.amber.shade400,
    Colors.cyan.shade400,
  ];
  List<String> _selectedProjects = [];

  void _handleProjectSelection(List<String> selectedProjects) {
    setState(() {
      _selectedProjects = selectedProjects;
    });
  }

  @override
  void initState() {
    super.initState();
    // Set default date range (current month)
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);

    _txtStartDate.text = DateFormat('yyyy-MM-dd').format(firstDay);
    _txtEndDate.text = DateFormat('yyyy-MM-dd').format(lastDay);

    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchDashboardData();
    });
  }

  Future<void> _selectDate(BuildContext context,
      TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  List<Map<String, dynamic>> _projectList = [];

  Future<void> _fetchDashboardData() async {
    PD.pd(text: _selectedProjects.toString());
    setState(() {
      _isLoading = true;
      _projectData = [];
      _hasData = false;
    });

    try {
      WaitDialog.showWaitDialog(context, message: 'Loading Dashboard Data');

      String reqUrl = '${APIHost()
          .apiURL}/report_controller.php/ViewProjectDashBoard';
      PD.pd(text: reqUrl);
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "Authorization": APIToken().token,
          "start_date": _txtStartDate.text,
          "end_date": _txtEndDate.text,
          "project_names": _selectedProjects,
          // Include selected projects in the request
        }),
      );

      PD.pd(text: reqUrl);
      if (response.statusCode == 200) {
        Navigator.pop(context);
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());
        final Map<String, dynamic> data = json.decode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            _projectData = responseData['data'] ?? [];
            final seenProjectNames = <String>{};
            _projectList =
                List<Map<String, dynamic>>.from(responseData['data'] ?? [])
                    .where((project) {
                  final name = project['project_name'];
                  if (name != null && !seenProjectNames.contains(name)) {
                    seenProjectNames.add(name);
                    return true;
                  }
                  return false;
                }).toList();
            _hasData = _projectData.isNotEmpty;
          });
        } else {
          final String message = responseData['message'] ??
              'Error fetching data';
          PD.pd(text: message);
          OneBtnDialog.oneButtonDialog(
            context,
            title: 'Error',
            message: message,
            btnName: 'OK',
            icon: Icons.error,
            iconColor: Colors.red,
            btnColor: Colors.black,
          );
        }
      } else {
        Navigator.pop(context);
        PD.pd(text: "HTTP Error: ${response.statusCode}");
      }
    } catch (e, st) {
      ExceptionLogger.logToError(message: e.toString(),
          errorLog: st.toString(),
          logFile: 'project_wise_dashboard.dart.dart');
      Navigator.pop(context);
      PD.pd(text: e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(appname: 'Project Dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                // Filter Card
                _buildFilterCard(),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  if (_hasData)
                    Column(
                      children: [
                        // Summary Cards
                        _buildSummaryCards(),
                        const SizedBox(height: 20),
                        // Charts Row
                        _buildChartsRow(context),
                        const SizedBox(height: 20),
                        // Data Table
                        _buildDataTable(),
                      ],
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'No project data available for the selected date range.',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleMedium,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Date Range Filter',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 16),
              MultiSelectDropDown(
                items: _projectList,
                label: 'Select Projects',
                onChanged: _handleProjectSelection,
                initialSelectedItems: _selectedProjects,
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    return Row(
                      children: [
                        Expanded(child: _buildDateSelection('Start Date',
                            _txtStartDate)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDateSelection('End Date',
                            _txtEndDate)),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildDateSelection('Start Date', _txtStartDate),
                        const SizedBox(height: 16),
                        _buildDateSelection('End Date', _txtEndDate),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchDashboardData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Fetch Data',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final currencyFormatter = NumberFormat.currency(
        locale: 'en_US', symbol: 'Rs. ');
    final numberFormatter = NumberFormat.decimalPattern();

    // Calculate totals
    double totalRequested = _projectData.fold(0, (sum, item) =>
    sum + (
        double.tryParse(item['totalReq'].toString()) ?? 0)
        + (double.tryParse(item['vat'].toString()) ?? 0)
        + (double.tryParse(item['sscl'].toString()) ?? 0)
        + (double.tryParse(item['ofz_list_total_amout'].toString()) ?? 0)
        - (double.tryParse(item['ofz_list_item_dis'].toString()) ?? 0)
        - (double.tryParse(item['item_disc'].toString()) ?? 0)
        - (double.tryParse(item['addt_discount'].toString()) ?? 0));
    double totalEstimated = _projectData.fold(0, (sum, item) => sum +
        (double.tryParse(item['estimated_amount'].toString()) ?? 0));
    double variance = totalEstimated - totalRequested;
    double variancePercentage = totalEstimated > 0 ? (variance /
        totalEstimated * 100) : 0;

    return LayoutBuilder(

      builder: (context, constraints) {
        double sw = MediaQuery
            .sizeOf(context)
            .width;
        if (constraints.maxWidth > 600) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatCard(
                title: 'Total Locations',
                value: _projectData.length.toString(),
                icon: Icons.assignment,
                color: Colors.indigo,
                formatter: numberFormatter,
              ),
              _buildStatCard(
                title: 'Total Requested',
                value: NumberStyles.currencyStyle(totalRequested.toString()),
                icon: Icons.request_quote,
                color: Colors.blue,
                formatter: currencyFormatter,
              ),
              _buildStatCard(
                title: 'Total Estimated',
                value: NumberStyles.currencyStyle(totalEstimated.toString()),
                icon: Icons.assessment,
                color: Colors.green,
                formatter: currencyFormatter,
              ),
              _buildStatCard(
                title: 'Variance',
                value:
                '${NumberStyles.currencyStyle(
                    variance.toString())} (${variancePercentage.toStringAsFixed(
                    1)}%)',
                icon: Icons.compare,
                color: variance >= 0 ? Colors.teal : Colors.orange,
                formatter: currencyFormatter,
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildStatCard(
                title: 'Total Projects',
                value: _projectData.length.toString(),
                icon: Icons.assignment,
                color: Colors.indigo,
                formatter: numberFormatter,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: 'Total Requested',
                value: NumberStyles.currencyStyle(totalRequested.toString()),
                icon: Icons.request_quote,
                color: Colors.blue,
                formatter: currencyFormatter,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: 'Total Estimated',
                value: NumberStyles.currencyStyle(totalEstimated.toString()),
                icon: Icons.assessment,
                color: Colors.green,
                formatter: currencyFormatter,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: 'Variance',
                value:
                '${NumberStyles.currencyStyle(
                    variance.toString())} (${variancePercentage.toStringAsFixed(
                    1)}%)',
                icon: Icons.compare,
                color: variance >= 0 ? Colors.teal : Colors.orange,
                formatter: currencyFormatter,
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required NumberFormat formatter,
  }) {
    return SizedBox(
      width: 250,
      height: 150,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(icon, color: color),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartsRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildProjectDistributionChart(),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 3,
                child: _buildComparisonChart(),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildProjectDistributionChart(),
              const SizedBox(height: 20),
              _buildComparisonChart(),
            ],
          );
        }
      },
    );
  }

  Widget _buildProjectDistributionChart() {
    final totalRequested = _projectData.fold(
        0.0, (sum, item) =>
    sum + (double.tryParse(item['totalReq'].toString()) ?? 0) -
        (double.tryParse(item['item_disc'].toString()) ?? 0) +
        (double.tryParse(item['ofz_list_total_amout'].toString()) ?? 0)
        - (double.tryParse(item['ofz_list_item_dis'].toString()) ?? 0));

    // Sort projects by requested amount in descending order
    final sortedProjects = [..._projectData];
    sortedProjects.sort((a, b) {
      final amountA = (double.tryParse(a['totalReq'].toString()) ?? 0) -
          (double.tryParse(a['item_disc'].toString()) ?? 0) +
          (double.tryParse(a['ofz_list_total_amout'].toString()) ?? 0)
          - (double.tryParse(a['ofz_list_item_dis'].toString()) ?? 0);
      final amountB = (double.tryParse(b['totalReq'].toString()) ?? 0) -
          (double.tryParse(b['item_disc'].toString()) ?? 0) +
          (double.tryParse(b['ofz_list_total_amout'].toString()) ?? 0)
          - (double.tryParse(b['ofz_list_item_dis'].toString()) ?? 0);
      return amountB.compareTo(amountA);
    });

    // Get top 10 projects
    final top10Projects = sortedProjects.take(10).toList();

    // Calculate the total for "Others" category
    double othersTotal = 0;
    for (var i = 10; i < sortedProjects.length; i++) {
      othersTotal +=
          (double.tryParse(sortedProjects[i]['totalReq'].toString()) ?? 0) -
              (double.tryParse(sortedProjects[i]['item_disc'].toString()) ??
                  0) + (double.tryParse(
              sortedProjects[i]['ofz_list_total_amout'].toString()) ?? 0)
              - (double.tryParse(
              sortedProjects[i]['ofz_list_item_dis'].toString()) ?? 0);
    }

    // Create data for pie chart sections
    final pieChartSections = <PieChartSectionData>[];
    for (var i = 0; i < top10Projects.length; i++) {
      final project = top10Projects[i];
      final amount = (double.tryParse(project['totalReq'].toString()) ?? 0) -
          (double.tryParse(project['item_disc'].toString()) ?? 0) +
          (double.tryParse(project['ofz_list_total_amout'].toString()) ?? 0)
          - (double.tryParse(project['ofz_list_item_dis'].toString()) ?? 0);
      final percentage = totalRequested > 0
          ? (amount / totalRequested * 100)
          : 0;
      pieChartSections.add(
        PieChartSectionData(
          value: amount,
          color: chartColors[i % chartColors.length],
          title: '',
          // Remove percentage from the slice
          radius: 24,
          titleStyle: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    if (othersTotal > 0) {
      pieChartSections.add(
        PieChartSectionData(
          value: othersTotal,
          color: chartColors[10 % chartColors.length],
          // Use a different color for "Others"
          title: '',
          radius: 24,
          titleStyle: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Project Distribution by Requested Amount',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        sections: pieChartSections,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...top10Projects
                            .asMap()
                            .entries
                            .map((entry) {
                          final index = entry.key;
                          final data = entry.value;
                          final amount = (double.tryParse(
                              data['totalReq'].toString()) ?? 0) -
                              (double.tryParse(data['item_disc'].toString()) ??
                                  0) + (double.tryParse(
                              data['ofz_list_total_amout'].toString()) ?? 0)
                              - (double.tryParse(
                                  data['ofz_list_item_dis'].toString()) ?? 0);
                          final percentage = totalRequested > 0 ? (amount /
                              totalRequested * 100) : 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: chartColors[index %
                                        chartColors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    data['location_name'],
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        if (othersTotal > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: chartColors[10 % chartColors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Others",
                                  style: TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${(othersTotal / totalRequested * 100)
                                      .toStringAsFixed(1)}%',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonChart() {
    // Group data by location with proper null safety
    final locationData = <String, Map<String, double>>{};

    for (final data in _projectData) {
      final location = data['location_name']?.toString() ?? 'Unknown Location';
      final sscl = double.tryParse(data['sscl']?.toString() ?? '0') ?? 0;
      final vat = double.tryParse(data['vat']?.toString() ?? '0') ?? 0;
      final totalReq = double.tryParse(data['totalReq']?.toString() ?? '0') ??
          0;
      final ofzAmount = double.tryParse(
          data['ofz_list_total_amout']?.toString() ?? '0') ?? 0;
      final ofzDisc = double.tryParse(
          data['ofz_list_item_dis']?.toString() ?? '0') ?? 0;
      final itemDisc = double.tryParse(data['item_disc']?.toString() ?? '0') ??
          0;
      final addDisc = double.tryParse(
          data['addt_discount']?.toString() ?? '0') ?? 0;

      final requested = totalReq + sscl + vat + ofzAmount - ofzDisc - itemDisc -
          addDisc;
      final estimated = double.tryParse(
          data['estimated_amount']?.toString() ?? '0') ?? 0;

      locationData.update(
        location,
            (value) =>
        {
          'requested': (value['requested'] ?? 0) + requested,
          'estimated': (value['estimated'] ?? 0) + estimated,
        },
        ifAbsent: () => {'requested': requested, 'estimated': estimated},
      );
    }

    // Convert to list and sort by requested amount (descending)
    var sortedLocations = locationData.entries.toList()
      ..sort((a, b) =>
          (b.value['requested'] ?? 0).compareTo(a.value['requested'] ?? 0));

    // Separate top 5 and others
    final top5 = sortedLocations.take(8).toList();
    final others = sortedLocations.skip(8).toList();

    // Calculate others total
    double othersRequested = 0;
    double othersEstimated = 0;
    for (final location in others) {
      othersRequested += location.value['requested'] ?? 0;
      othersEstimated += location.value['estimated'] ?? 0;
    }

    // Prepare final chart data
    final chartData = <Map<String, dynamic>>[];

    // Add top 5 locations
    for (final location in top5) {
      chartData.add({
        'location': location.key,
        'requested': location.value['requested'] ?? 0.0,
        'estimated': location.value['estimated'] ?? 0.0,
      });
    }

    // Add others if they exist
    if (others.isNotEmpty) {
      chartData.add({
        'location': 'Others',
        'requested': othersRequested,
        'estimated': othersEstimated,
      });
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Requested vs Estimated Amount (Top 8 Locations)',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 320,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelRotation: -45,
                  labelIntersectAction: AxisLabelIntersectAction.rotate45,
                ),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.compactCurrency(symbol: 'Rs. '),
                  title: AxisTitle(text: 'Amount (LKR)'),
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  builder: (data, point, series, pointIndex, seriesIndex) {
                    final location = chartData[pointIndex]['location'] as String;
                    final requested = chartData[pointIndex]['requested'] as double;
                    final estimated = chartData[pointIndex]['estimated'] as double;
                    final variance = estimated - requested;
                    final variancePercent = estimated > 0 ? (variance /
                        estimated * 100) : 0;

                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Requested: ${NumberFormat.currency(
                              symbol: 'Rs. ').format(requested)}'),
                          Text('Estimated: ${NumberFormat.currency(
                              symbol: 'Rs. ').format(estimated)}'),
                          const SizedBox(height: 4),
                          Text(
                            'Variance: ${NumberFormat.currency(symbol: 'Rs. ')
                                .format(variance)} (${variancePercent
                                .toStringAsFixed(1)}%)',
                            style: TextStyle(
                              color: variance >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                series: <CartesianSeries>[
                  ColumnSeries<Map<String, dynamic>, String>(
                    dataSource: chartData,
                    xValueMapper: (data, _) => data['location'] as String,
                    yValueMapper: (data, _) => data['requested'] as double,
                    name: 'Requested',
                    color: Colors.blue.shade400,
                    width: 0.4,
                    spacing: 0.2,
                  ),
                  ColumnSeries<Map<String, dynamic>, String>(
                    dataSource: chartData,
                    xValueMapper: (data, _) => data['location'] as String,
                    yValueMapper: (data, _) => data['estimated'] as double,
                    name: 'Estimated',
                    color: Colors.green.shade400,
                    width: 0.4,
                    spacing: 0.2,
                  ),
                ],
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  overflowMode: LegendItemOverflowMode.wrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Project Details',
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _fetchDashboardData,
                      tooltip: 'Refresh Data',
                    ),
                    /* IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Export functionality would be implemented here')),
                        );
                      },
                      tooltip: 'Export Data',
                    ),*/
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                horizontalMargin: 12,
                columns: const [
                  DataColumn(label: Text('Project')),
                  DataColumn(label: Text('Location'), numeric: false),
                  DataColumn(label: Text('Requested'), numeric: true),
                  DataColumn(label: Text('Estimated'), numeric: true),
                  DataColumn(label: Text('Variance'), numeric: true),
                  DataColumn(label: Text('Variance %'), numeric: true),
                  DataColumn(label: Text('Start Date')),
                  DataColumn(label: Text('End Date')),
                ],
                rows: _projectData.map((data) {
                  double requested =
                      (double.tryParse(data['sscl'].toString()) ?? 0)
                          + (double.tryParse(data['vat'].toString()) ?? 0)
                          + (double.tryParse(data['totalReq'].toString()) ?? 0)
                          + (double.tryParse(data['ofz_list_total_amout']
                          .toString()) ?? 0)
                          - (double.tryParse(data['ofz_list_item_dis']
                          .toString()) ?? 0)
                          - (double.tryParse(data['item_disc'].toString()) ?? 0)
                          -
                          (double.tryParse(data['addt_discount'].toString()) ??
                              0);
                  double estimated =
                      double.tryParse(data['estimated_amount'].toString()) ?? 0;
                  double variance = estimated - requested;
                  double variancePercent =
                  estimated > 0 ? (variance / estimated * 100) : 0;

                  return DataRow(
                    cells: [
                      DataCell(Text(data['project_name'])),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Text(
                            data['location_name'],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(
                          NumberStyles.currencyStyle(requested.toString()))),
                      DataCell(Text(
                          NumberStyles.currencyStyle(estimated.toString()))),
                      DataCell(
                        Text(
                          NumberStyles.currencyStyle(variance.toString()),
                          style: TextStyle(
                            color: variance >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${variancePercent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: variance >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(Text(data['start_date'])),
                      DataCell(Text(data['end_date'])),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context, controller),
          child: IgnorePointer(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Select $label',
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}