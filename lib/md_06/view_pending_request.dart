import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:roky_holding/env/user_data.dart';
import '../env/api_info.dart';
import '../env/app_logs_to.dart';
import '../env/print_debug.dart';
import '../md_04/view_ofz_request_list.dart';
import '../md_04/view_project_request_item_list.dart';

class ApiResponse {
  final int status;
  final List<NotificationItem> data;

  ApiResponse({required this.status, required this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    if (json['status'] == 200) {
      return ApiResponse(
        status: json['status'],
        data: (json['data'] as List)
            .map((item) => NotificationItem.fromJson(item))
            .toList(),
      );
    } else {
      return ApiResponse(
        status: json['status'],
        data: [], // Return empty list when status is not 200
      );
    }
  }
}

class NotificationItem {
  final String reqRefNumber;
  final String id;
  final String createdBy;
  final String createdDate;
  final String currentEventType;
  final String type;

  NotificationItem({

    required this.reqRefNumber,
    required this.id,
    required this.createdBy,
    required this.createdDate,
    required this.currentEventType,
    required this.type,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['idtbl_ofz_request'].toString(),
      reqRefNumber: json['req_ref_number'],
      createdBy: json['created_by'],
      createdDate: json['created_date'],
      currentEventType: json['current_event_type'],
      type: json['type'],
    );
  }

  DateTime get parsedDate => DateTime.parse(createdDate);
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<ApiResponse> _notificationsFuture;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _fetchNotifications();
  }

  Future<ApiResponse> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final String reqUrl = '${APIHost()
        .apiURL}/report_controller.php/GetPendingRequests';
    PD.pd(text: reqUrl);
    try {
      final response = await http.post(
        Uri.parse(reqUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Authorization": APIToken().token,
          'user_name': UserCredentials().UserName
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        PD.pd(text: responseData.toString());

        return ApiResponse.fromJson(responseData);
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e, st) {
      ExceptionLogger.logToError(
          message: e.toString(),
          errorLog: st.toString(),
          logFile: 'notifications_screen.dart'
      );
      throw Exception('Error fetching notifications: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _notificationsFuture = _fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshNotifications,
          ),
        ],
      ),
      body: _buildResponsiveBody(),
    );
  }

  Widget _buildResponsiveBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: _refreshNotifications,
          child: FutureBuilder<ApiResponse>(
            future: _notificationsFuture,
            builder: (context, snapshot) {
              // Loading state
              if (_isLoading && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Error state
              if (snapshot.hasError) {
                return _buildErrorView(snapshot.error.toString());
              }

              // Data loaded state
              if (snapshot.hasData) {
                final notifications = snapshot.data!.data;
                if (notifications.isEmpty) {
                  return _buildEmptyState();
                }
                return constraints.maxWidth < 600
                    ? _buildDesktopTable(notifications)
                    : _buildDesktopTable(notifications);
              }

              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load notifications',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshNotifications,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No notifications available',
            style: Theme
                .of(context)
                .textTheme
                .titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(List<NotificationItem> notifications) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: _getTypeColor(notification.type).withOpacity(
                  0.1),
              child: Icon(
                  Icons.notifications, color: _getTypeColor(notification.type)),
            ),
            title: RichText(
              text: TextSpan(
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black87),
                children: [
                  TextSpan(
                    text: notification.createdBy,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' • '),
                  TextSpan(text: notification.currentEventType),
                ],
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Chip(
                      label: Text(notification.type,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                      backgroundColor: _getTypeColor(notification.type),
                      visualDensity: VisualDensity.compact,
                    ),
                    Text(_formatDate(notification.parsedDate),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                    Text('Ref: ${notification.reqRefNumber}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        notification.type == 'office'
                            ? ViewOfzRequestList(
                          requestId: notification.id.toString(),
                          isNotApprove: true,
                          refNumber: notification.reqRefNumber.toString(),
                        )
                            : ViewConstructionRequestList(
                          requestId: notification.id.toString(),
                          isNotApprove: true,
                          refNumber: notification.reqRefNumber.toString(),
                        ),
                      ),
                    )
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(List<NotificationItem> notifications) {
    return
      Center(
        child: SingleChildScrollView(

          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  horizontalMargin: 16,
                  headingRowHeight: 48,
                  dataRowHeight: 64,
                  headingRowColor: MaterialStateProperty.resolveWith(
                        (states) => Colors.grey.shade100,
                  ),
                  columns: const [
                    DataColumn(
                      label: Text('Ref No.',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    DataColumn(
                      label: Text('Type',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    DataColumn(
                      label: Text('Event',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    DataColumn(
                      label: Text('Created By',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    DataColumn(
                      label: Text('Date',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    DataColumn(
                      label: Text('Actions',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                  rows: notifications.map((notification) {
                    return DataRow(
                      cells: [
                        DataCell(Text(notification.reqRefNumber,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500))),
                        DataCell(
                          Chip(
                            label: Text(notification.type,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                            backgroundColor: _getTypeColor(notification.type),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        DataCell(Text(notification.currentEventType)),
                        DataCell(Text(notification.createdBy)),
                        DataCell(Text(_formatDate(notification.parsedDate))),
                        DataCell(
                          IconButton(
                              icon: const Icon(
                                  Icons.visibility, color: Colors.blue),
                              onPressed: () =>
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                      notification.type == 'office'
                                          ? ViewOfzRequestList(
                                        requestId: notification.id.toString(),
                                        isNotApprove: true,
                                        refNumber: notification.reqRefNumber
                                            .toString(),
                                      )
                                          : ViewConstructionRequestList(
                                        requestId: notification.id.toString(),
                                        isNotApprove: true,
                                        refNumber: notification.reqRefNumber
                                            .toString(),
                                      ),
                                    ),
                                  )
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'office':
        return Colors.blue.shade700;
      case 'mannar':
        return Colors.green.shade700;
      case 'common project':
        return Colors.orange.shade700;
      case 'homadola':
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}m ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _viewNotification(NotificationItem notification) {
    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                            Icons.notifications, size: 28, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Details: ${notification.reqRefNumber}',
                            style: Theme
                                .of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildDetailRow('Type', notification.type),
                    _buildDetailRow('Event', notification.currentEventType),
                    _buildDetailRow('Created By', notification.createdBy),
                    _buildDetailRow('Date', notification.createdDate),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}