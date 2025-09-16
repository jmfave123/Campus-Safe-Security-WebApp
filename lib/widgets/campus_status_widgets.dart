// campus_status_widgets.dart
import 'package:flutter/material.dart';
import '../models/campus_status_model.dart';
import '../services/audit_wrapper.dart';

class CampusStatusIndicator extends StatelessWidget {
  final CampusStatus status;
  final double size;

  const CampusStatusIndicator({
    super.key,
    required this.status,
    this.size = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16 * size),
      decoration: BoxDecoration(
        color: status.level.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12 * size),
        border: Border.all(
          color: status.level.color.withOpacity(0.3),
          width: 1.5 * size,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.level.icon,
            color: status.level.color,
            size: 24 * size,
          ),
          SizedBox(width: 12 * size),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Campus Status: ${status.level.name}',
                style: TextStyle(
                  fontSize: 16 * size,
                  fontWeight: FontWeight.bold,
                  color: status.level.color,
                ),
              ),
              SizedBox(height: 4 * size),
              Text(
                status.reason,
                style: TextStyle(
                  fontSize: 14 * size,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4 * size),
              Text(
                'Updated: ${status.timestamp.toString().substring(0, 16)}',
                style: TextStyle(
                  fontSize: 12 * size,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CampusStatusControl extends StatefulWidget {
  final CampusStatus currentStatus;
  final Function(CampusStatusLevel, String) onStatusUpdate;

  const CampusStatusControl({
    super.key,
    required this.currentStatus,
    required this.onStatusUpdate,
  });

  @override
  _CampusStatusControlState createState() => _CampusStatusControlState();
}

class _CampusStatusControlState extends State<CampusStatusControl> {
  late CampusStatusLevel _selectedLevel;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.currentStatus.level;
    _reasonController.text = widget.currentStatus.reason;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Update Campus Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<CampusStatusLevel>(
            initialValue: _selectedLevel,
            decoration: InputDecoration(
              labelText: 'Status Level',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: CampusStatusLevel.values.map((level) {
              return DropdownMenuItem<CampusStatusLevel>(
                value: level,
                child: Row(
                  children: [
                    Icon(level.icon, color: level.color, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      level.name,
                      style: TextStyle(color: level.color),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedLevel = newValue;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: 'Reason for Status Change',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_reasonController.text.trim().isNotEmpty) {
                // Log the status update
                AuditWrapper.instance.logStatusUpdate(
                  newStatus: _selectedLevel.name,
                  reason: _reasonController.text.trim(),
                  previousStatus: widget.currentStatus.level.name,
                );

                widget.onStatusUpdate(
                    _selectedLevel, _reasonController.text.trim());
              } else {
                // Show error that reason is required
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Please provide a reason for the status change')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedLevel.color,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Update Status',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
