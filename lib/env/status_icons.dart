import 'package:flutter/material.dart';

class StatusIcon extends StatelessWidget {
  final int statusId;

  const StatusIcon({super.key, required this.statusId});

  @override
  Widget build(BuildContext context) {
    final statusData = _getStatusData(statusId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          statusData.icon,
          size: 30.0,
          color: statusData.color,
        ),
        const SizedBox(height: 4),
        Text(
          statusData.label,
          style: TextStyle(
            fontSize: 12,
            color: statusData.color,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  _StatusData _getStatusData(int statusId) {
    switch (statusId) {
      case 1:
        return _StatusData(Icons.add_box, Colors.blue, 'Create');
      case 2:
        return _StatusData(Icons.edit, Colors.orange, 'Edit');
      case 3:
        return _StatusData(Icons.block, Colors.red, 'Disabled');
      case 4:
        return _StatusData(Icons.error, Colors.redAccent, 'Rejected Auth');
      case 5:
        return _StatusData(Icons.check_circle, Colors.green, 'Authorized');
      case 6:
        return _StatusData(Icons.check, Colors.greenAccent, 'Approved');
      case 7:
        return _StatusData(Icons.refresh, Colors.purple, 'Status Changed');
      case 8:
        return _StatusData(Icons.payment, Colors.teal, 'Payment Approved');
      case 9:
        return _StatusData(Icons.done_all, Colors.indigo, 'Payment Done');
      case 10:
        return _StatusData(Icons.stop, Colors.grey, 'Ended');
      case 11:
        return _StatusData(Icons.remove_circle, Colors.red, 'Item Removed');
      case 12:
        return _StatusData(Icons.settings, Colors.blueGrey, 'Qty/Price Changed');
      case 13:
        return _StatusData(Icons.cancel, Colors.redAccent, 'Rejected Approval');
      case 14:
        return _StatusData(Icons.assignment, Colors.deepPurple, 'Data Entered');
      case 15:
        return _StatusData(Icons.cancel_outlined, Colors.red, 'Payment Rejected');
      default:
        return _StatusData(Icons.help_outline, Colors.black, 'Unknown');
    }
  }
}

class _StatusData {
  final IconData icon;
  final Color color;
  final String label;

  const _StatusData(this.icon, this.color, this.label);
}
