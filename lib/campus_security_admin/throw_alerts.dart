// ignore_for_file: avoid_web_libraries_in_flutter, unnecessary_import, unused_local_variable, use_build_context_synchronously, unused_element, deprecated_member_use

import 'package:campus_safe_app_admin_capstone/reusable_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/notify_services.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import '../widgets/skeleton_loader.dart';

enum AlertTarget { student, facultyStaff, all }

class ThrowAlertsPage extends StatefulWidget {
  const ThrowAlertsPage({super.key});

  @override
  State<ThrowAlertsPage> createState() => _ThrowAlertsPageState();
}

class _ThrowAlertsPageState extends State<ThrowAlertsPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  AlertTarget _selectedTarget = AlertTarget.all; // Default to all
  String _selectedDateFilter = "All";
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _getTargetText(AlertTarget target) {
    switch (target) {
      case AlertTarget.student:
        return 'Student';
      case AlertTarget.facultyStaff:
        return 'Faculty & Staff';
      case AlertTarget.all:
        return 'All Users';
    }
  }

  Future<void> _sendPushNotification(String message) async {
    try {
      String userType;
      switch (_selectedTarget) {
        case AlertTarget.student:
          userType = "Student"; // Exact match with your userType
          break;
        case AlertTarget.facultyStaff:
          userType = "Faculty & Staff"; // Exact match with your userType
          break;
        case AlertTarget.all:
          // Send to both groups
          await Future.wait([
            NotifServices.sendGroupNotification(
              userType: "Student",
              heading: "Security Announcement",
              content: message,
            ),
            NotifServices.sendGroupNotification(
              userType: "Faculty & Staff",
              heading: "Security Announcement",
              content: message,
            ),
          ]);
          return;
      }

      await NotifServices.sendGroupNotification(
        userType: userType,
        heading:
            "Security Alert", // Using a direct string instead of undefined method
        content: message,
      );

      print('Sending notification to userType: $userType'); // Debug print
    } catch (e) {
      print('Push notification error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Announcement saved but notification delivery may have failed: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _throwAlert() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an alert message')),
      );
      return;
    }

    // Show confirmation dialog
    final bool confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create alert document with target audience
      final alertData = {
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        'target': _selectedTarget.toString().split('.').last,
        'targetDisplay': _getTargetText(_selectedTarget),
      };

      final docRef = await FirebaseFirestore.instance
          .collection('alerts_data')
          .add(alertData);

      // Send push notification
      await _sendPushNotification(_messageController.text.trim());

      if (!mounted) return;

      // Show receipt of the alert sent
      await _showAlertReceipt(alertData);

      // Clear the input
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending alert: $e')),
      );
      print('Error details: $e'); // For debugging
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue.shade50, Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Confirm Alert',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Are you sure you want to send this alert to ${_getTargetText(_selectedTarget)}?',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        _messageController.text.trim(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blueGrey,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          child: const Text('Send Alert'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  Future<void> _showAlertReceipt(Map<String, dynamic> alertData) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade50, Colors.white],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Alert Sent Successfully',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                receiptInfoRow(
                  Icons.message,
                  'Message',
                  alertData['message'],
                ),
                const SizedBox(height: 12),
                receiptInfoRow(
                  Icons.people,
                  'Recipients',
                  alertData['targetDisplay'],
                ),
                const SizedBox(height: 12),
                receiptInfoRow(
                  Icons.access_time,
                  'Time',
                  DateFormat('MMM d, y HH:mm').format(DateTime.now()),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title only (filter button moved)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: Colors.blue,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Send Announcements',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),

                if (_selectedDateFilter == 'Custom' &&
                    _customStartDate != null &&
                    _customEndDate != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.date_range,
                            size: 18, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Date range: ${_formatDate(_customStartDate)} - ${_formatDate(_customEndDate)}',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Statistics Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    return constraints.maxWidth < 600
                        ? Column(
                            children: [
                              buildStatCardAlerts(
                                'Total Announcements',
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('alerts_data')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const SkeletonStatCard();
                                    }
                                    return Text(
                                      snapshot.hasData
                                          ? '${snapshot.data?.docs.length ?? 0}'
                                          : 'Loading...',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    );
                                  },
                                ),
                                Icons.notifications_active,
                                const Color(0xFF4285F4),
                              ),
                              const SizedBox(height: 16),
                              buildStatCardAlerts(
                                'Active Announcements',
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('alerts_data')
                                      .where('status', isEqualTo: 'active')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const SkeletonStatCard();
                                    }
                                    return Text(
                                      snapshot.hasData
                                          ? '${snapshot.data?.docs.length ?? 0}'
                                          : 'Loading...',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    );
                                  },
                                ),
                                Icons.warning_rounded,
                                const Color(0xFFFF9800),
                              ),
                              const SizedBox(height: 16),
                              buildStatCardAlerts(
                                'Announcement Channels',
                                const Text(
                                  'Mobile App',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Icons.phone_android,
                                const Color(0xFF0F9D58),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: buildStatCardAlerts(
                                  'Total Announcements',
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('alerts_data')
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SkeletonStatCard();
                                      }
                                      return Text(
                                        snapshot.hasData
                                            ? '${snapshot.data?.docs.length ?? 0}'
                                            : 'Loading...',
                                        style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color.fromARGB(255, 227, 26, 32),
                                        ),
                                      );
                                    },
                                  ),
                                  Icons.notifications_active,
                                  const Color.fromARGB(255, 227, 26, 32),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: buildStatCardAlerts(
                                  'Active Announcements',
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('alerts_data')
                                        .where('status', isEqualTo: 'active')
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SkeletonStatCard();
                                      }
                                      return Text(
                                        snapshot.hasData
                                            ? '${snapshot.data?.docs.length ?? 0}'
                                            : 'Loading...',
                                        style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFF9800),
                                        ),
                                      );
                                    },
                                  ),
                                  Icons.warning_rounded,
                                  const Color(0xFFFF9800),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: buildStatCardAlerts(
                                  'Announcement Channel',
                                  const Text(
                                    'Mobile App',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F9D58),
                                    ),
                                  ),
                                  Icons.phone_android,
                                  const Color(0xFF0F9D58),
                                ),
                              ),
                            ],
                          );
                  },
                ),

                const SizedBox(height: 24),

                // Send New Alert Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add_alert,
                                color: Colors.red,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Send an Announcement',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<AlertTarget>(
                          value: _selectedTarget,
                          decoration: InputDecoration(
                            labelText: 'Send Announcement To',
                            labelStyle: TextStyle(
                              color: Colors.blueGrey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.blueGrey.withOpacity(0.2),
                                  width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.blueGrey.withOpacity(0.2),
                                  width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Colors.blue, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.people,
                                color: Colors.blueGrey.shade600, size: 22),
                          ),
                          dropdownColor: Colors.white,
                          icon: Icon(Icons.arrow_drop_down,
                              color: Colors.blueGrey.shade600),
                          items: AlertTarget.values.map((target) {
                            return DropdownMenuItem(
                              value: target,
                              child: Text(
                                _getTargetText(target),
                                style: TextStyle(
                                  color: Colors.blueGrey.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (AlertTarget? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedTarget = newValue;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _messageController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Enter announcement message...',
                            labelText: 'Announcement Message',
                            hintStyle:
                                TextStyle(color: Colors.blueGrey.shade300),
                            labelStyle: TextStyle(
                              color: Colors.blueGrey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.blueGrey.withOpacity(0.2),
                                  width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.blueGrey.withOpacity(0.2),
                                  width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Colors.blue, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                  left: 12, right: 8, top: 12, bottom: 12),
                              child: Icon(Icons.message,
                                  color: Colors.blueGrey.shade600, size: 22),
                            ),
                            alignLabelWithHint: true,
                          ),
                          cursorColor: Colors.blue,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<int>(
                          future: _getTargetCount(_selectedTarget),
                          builder: (context, snapshot) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people,
                                      size: 20, color: Colors.blue.shade600),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Recipients: ${snapshot.data ?? "..."}',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _throwAlert,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: const Text(
                              'Send Announcement',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Recent Alerts Card
                Container(
                  height: 500, // Fixed height for alerts list
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.history,
                                    size: 24, color: Colors.blue.shade700),
                                const SizedBox(width: 12),
                                Text(
                                  'Recent Announcements',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                            // Action buttons row
                            Row(
                              children: [
                                // Generate Report Button
                                _buildGenerateReportButton(),
                                const SizedBox(width: 12),
                                // Filter button
                                _buildDateFilterButton(),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _getFilteredAlertsStream(),
                          builder: (context, snapshot) {
                            final count =
                                snapshot.hasData ? snapshot.data!.size : 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Text(
                                '$count alert${count == 1 ? '' : 's'} found',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildAlertsListView(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24), // Add bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Filter by date',
        onSelected: (String value) {
          setState(() {
            _selectedDateFilter = value;
            if (value != 'Custom') {
              _customStartDate = null;
              _customEndDate = null;
            }
          });
          if (value == 'Custom') {
            _showDateRangePicker();
          }
        },
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        itemBuilder: (BuildContext context) => [
          _buildPopupMenuItem('Today', Icons.today),
          _buildPopupMenuItem('Yesterday', Icons.history),
          _buildPopupMenuItem('Last Week', Icons.date_range),
          _buildPopupMenuItem('Last Month', Icons.calendar_month),
          _buildPopupMenuItem('All', Icons.all_inclusive),
          _buildPopupMenuItem('Custom', Icons.calendar_today),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_list, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Filter: $_selectedDateFilter',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, IconData icon) {
    final isSelected = _selectedDateFilter == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.blue : Colors.grey.shade700,
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.black,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check, size: 16, color: Colors.blue),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertsListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredAlertsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SkeletonLoader(height: 40, borderRadius: 8),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading announcements: ${snapshot.error}',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ],
            ),
          );
        }

        final alerts = snapshot.data?.docs ?? [];

        if (alerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No announcements found for the selected time period',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedDateFilter = 'All';
                      _customStartDate = null;
                      _customEndDate = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('View all announcements'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: alerts.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final alert = alerts[index].data() as Map<String, dynamic>;
            final timestamp = alert['timestamp'] as Timestamp?;
            final formattedDate = timestamp != null
                ? DateFormat('MMM d, y HH:mm').format(timestamp.toDate())
                : 'Time not available';
            final status = alert['status'] ?? 'active';
            final isActive = status == 'active';

            return Card(
              elevation: 0,
              color: isActive ? Colors.grey.shade50 : Colors.grey.shade100,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.red.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.notifications,
                      color: isActive ? Colors.red : Colors.grey, size: 24),
                ),
                title: Text(
                  alert['message'] ?? 'No message',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isActive ? Colors.black87 : Colors.black54,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.people,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          FutureBuilder<Map<String, int>>(
                            future: _getDetailedTargetCount(alert['target']),
                            builder: (context, snapshot) {
                              final String targetDisplay =
                                  alert['targetDisplay'] ?? 'All Users';
                              String countDisplay = '';

                              if (snapshot.hasData) {
                                if (alert['target'] == 'all') {
                                  countDisplay =
                                      ' (${snapshot.data!['students'] ?? 0} Students, ${snapshot.data!['faculty'] ?? 0} Faculty & Staff)';
                                } else if (alert['target'] == 'student') {
                                  countDisplay =
                                      ' (${snapshot.data!['students'] ?? 0} Students)';
                                } else if (alert['target'] == 'facultyStaff') {
                                  countDisplay =
                                      ' (${snapshot.data!['faculty'] ?? 0} Faculty & Staff)';
                                }
                              }

                              return Text(
                                'Sent to: $targetDisplay$countDisplay',
                                style: TextStyle(
                                    color: Colors.grey.shade700, fontSize: 12),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isActive
                                    ? Colors.green.shade200
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isActive
                                    ? Colors.green.shade700
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.edit_outlined, color: Colors.blue.shade600),
                  tooltip: 'Edit Alert',
                  onPressed: () async {
                    final docId = alerts[index].id;
                    final bool? success =
                        await _showEditAlertDialog(docId, alert);
                    if (success == true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Alert updated successfully')),
                      );
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(
              start: _customStartDate!,
              end: _customEndDate!,
            )
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          // Wrap in a container to control the size
          child: Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 400,
                maxHeight: 480,
              ),
              child: child!,
            ),
          ),
        );
      },
    );

    if (dateRange != null) {
      setState(() {
        _selectedDateFilter = 'Custom';
        _customStartDate = dateRange.start;
        _customEndDate = dateRange.end;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Future<int> _getTargetCount(AlertTarget target) async {
    try {
      QuerySnapshot query;
      if (target == AlertTarget.all) {
        query = await FirebaseFirestore.instance.collection('users').get();
      } else {
        String userType =
            target == AlertTarget.student ? 'Student' : 'Faculty & Staff';
        query = await FirebaseFirestore.instance
            .collection('users')
            .where('userType', isEqualTo: userType)
            .get();
      }
      return query.docs.length;
    } catch (e) {
      print('Error getting target count: $e');
      return 0;
    }
  }

  Stream<QuerySnapshot> _getFilteredAlertsStream() {
    Query query = FirebaseFirestore.instance.collection('alerts_data');

    // Apply date filters
    if (_selectedDateFilter != 'All') {
      DateTime now = DateTime.now();
      DateTime startDate;
      DateTime endDate;

      switch (_selectedDateFilter) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          endDate = now;
          break;
        case 'Yesterday':
          startDate = DateTime(now.year, now.month, now.day - 1);
          endDate = DateTime(now.year, now.month, now.day)
              .subtract(const Duration(milliseconds: 1));
          break;
        case 'Last Week':
          startDate = DateTime(now.year, now.month, now.day - 7);
          endDate = now;
          break;
        case 'Last Month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          endDate = now;
          break;
        case 'Custom':
          if (_customStartDate != null && _customEndDate != null) {
            startDate = _customStartDate!;
            endDate = _customEndDate!
                .add(const Duration(days: 1))
                .subtract(const Duration(milliseconds: 1));
          } else {
            return query
                .orderBy('timestamp', descending: true)
                .limit(10)
                .snapshots();
          }
          break;
        default: // 'All'
          return query
              .orderBy('timestamp', descending: true)
              .limit(10)
              .snapshots();
      }

      return query
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots();
    }

    // Default to showing all recent alerts
    return query.orderBy('timestamp', descending: true).limit(10).snapshots();
  }

  Future<bool?> _showEditAlertDialog(
      String docId, Map<String, dynamic> alert) async {
    final TextEditingController editController =
        TextEditingController(text: alert['message']);
    AlertTarget selectedTarget = AlertTarget.values.firstWhere(
      (target) => target.toString().split('.').last == alert['target'],
      orElse: () => AlertTarget.all,
    );

    String currentStatus = alert['status'] ?? 'active';
    bool isActive = currentStatus == 'active';

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade50, Colors.white],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Edit Alert',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<AlertTarget>(
                    value: selectedTarget,
                    decoration: InputDecoration(
                      labelText: 'Alert Target',
                      labelStyle: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue.shade300,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue.shade300,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.blue.withOpacity(0.05),
                      prefixIcon: Icon(
                        Icons.people,
                        color: Colors.blue.shade600,
                        size: 22,
                      ),
                    ),
                    dropdownColor: Colors.white,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.blue.shade600,
                    ),
                    items: AlertTarget.values.map((target) {
                      return DropdownMenuItem(
                        value: target,
                        child: Text(
                          _getTargetText(target),
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (AlertTarget? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedTarget = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: editController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Alert Message',
                      hintText: 'Edit alert message...',
                      labelStyle: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      hintStyle: TextStyle(
                        color: Colors.blue.shade300,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue.shade300,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue.shade300,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.blue.withOpacity(0.05),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(
                            left: 12, right: 8, top: 12, bottom: 12),
                        child: Icon(
                          Icons.message,
                          color: Colors.blue.shade600,
                          size: 22,
                        ),
                      ),
                      alignLabelWithHint: true,
                    ),
                    cursorColor: Colors.blue,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Status:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: isActive,
                        onChanged: isActive
                            ? (value) {
                                setState(() {
                                  isActive = value;
                                });
                              }
                            : null, // Null makes the switch disabled if already inactive
                        activeColor: Colors.green,
                        activeTrackColor: Colors.green.withOpacity(0.5),
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.withOpacity(0.5),
                      ),
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                        ),
                      ),
                      if (!isActive) ...[
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Inactive alerts cannot be reactivated',
                          child: Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blueGrey,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (editController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Alert message cannot be empty')),
                            );
                            return;
                          }

                          try {
                            await FirebaseFirestore.instance
                                .collection('alerts_data')
                                .doc(docId)
                                .update({
                              'message': editController.text.trim(),
                              'target':
                                  selectedTarget.toString().split('.').last,
                              'targetDisplay': _getTargetText(selectedTarget),
                              'status': isActive ? 'active' : 'inactive',
                            });
                            Navigator.of(context).pop(true);
                          } catch (e) {
                            print('Error updating alert: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error updating alert: $e')),
                            );
                            Navigator.of(context).pop(false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        child: const Text('Update'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );

    editController.dispose();
    return result;
  }

  // Add this new widget for the report generation button
  Widget _buildGenerateReportButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text('Generate Report'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () async {
        try {
          // Check if there's data available first
          final QuerySnapshot alertsSnapshot =
              await _getFilteredAlertsQuery().get();

          if (alertsSnapshot.docs.isEmpty) {
            // Show no data dialog
            showDialog(
              context: context,
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                child: Container(
                  width: 360, // Constrain dialog width
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.info_outline,
                            color: Colors.orange, size: 38),
                      ),
                      const SizedBox(height: 16),
                      Text('No Data Found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          )),
                      const SizedBox(height: 12),
                      const Text(
                        'There are no alerts for the selected time period. Please adjust your filter or try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blueGrey, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('OK'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
            return;
          }

          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const Dialog(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Generating report...'),
                    ],
                  ),
                ),
              );
            },
          );

          // Get alerts data based on current filter
          final List<Map<String, dynamic>> alertsData =
              alertsSnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as Timestamp?;
            final formattedDate = timestamp != null
                ? DateFormat('MMM d, y HH:mm').format(timestamp.toDate())
                : 'Time not available';

            return {
              'message': data['message'] ?? 'No message',
              'date': formattedDate,
              'status': data['status'] ?? 'unknown',
              'target': data['targetDisplay'] ?? 'All Users',
            };
          }).toList();

          // Close loading dialog
          Navigator.of(context).pop();

          // Show report options dialog
          _showReportOptionsDialog(alertsData);
        } catch (e) {
          // Close loading dialog if there's an error
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error generating report: $e')),
          );
        }
      },
    );
  }

  // Show report options dialog
  Future<void> _showReportOptionsDialog(
      List<Map<String, dynamic>> alertsData) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: Colors.white,
          child: Container(
            width: 400, // Constrain dialog width
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded,
                      color: Colors.blue, size: 38),
                ),
                const SizedBox(height: 16),
                Text('Generate Report?',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800)),
                const SizedBox(height: 12),
                Text(
                  'This will generate a PDF report for ${alertsData.length} alert${alertsData.length == 1 ? '' : 's'} in the selected period.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 15, color: Colors.blueGrey.shade700),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blueGrey,
                          side: BorderSide(color: Colors.blue.shade100),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Generate'),
                        onPressed: () {
                          Navigator.pop(context);
                          _generatePDFReport(alertsData);
                        },
                      ),
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

  Widget _buildReportFormatButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PDF Report Generation
  Future<void> _generatePDFReport(List<Map<String, dynamic>> alertsData) async {
    try {
      // Create a PDF document
      final pdf = pw.Document();

      // Load the logo image
      final ByteData logoData = await rootBundle.load('assets/ustpLogo.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final logoImage = pw.MemoryImage(logoBytes);

      // Add a title page
      pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Add logo image to the PDF at the top left
                pw.Image(logoImage, width: 200, height: 100),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Campus Safety Alerts Report',
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'Generated on: ${DateFormat('MMMM d, y HH:mm').format(DateTime.now())}',
                        style: const pw.TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Filter: $_selectedDateFilter',
                        style: const pw.TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      pw.SizedBox(height: 30),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(5)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Summary:',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(
                                'Total Announcements: ${alertsData.length}'),
                            pw.SizedBox(height: 5),
                            pw.Text(
                                'Active Announcements: ${alertsData.where((alert) => alert['status'] == 'active').length}'),
                            pw.SizedBox(height: 5),
                            pw.Text(
                                'Inactive Announcements: ${alertsData.where((alert) => alert['status'] != 'active').length}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }));

      // Create a table for the alert data
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Add logo to subsequent pages (smaller size)
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo at the top left
                      pw.Image(logoImage, width: 100, height: 50),
                      pw.Text(
                        'Campus Safety Alerts - Details',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ]),
                pw.SizedBox(height: 5),
                pw.Divider(),
              ],
            );
          },
          build: (pw.Context context) {
            // Create a table
            return [
              pw.Table.fromTextArray(
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                headerHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                },
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                cellPadding: const pw.EdgeInsets.all(5),
                headers: ['Alert Message', 'Date', 'Target', 'Status'],
                data: alertsData.map((alert) {
                  return [
                    alert['message'],
                    alert['date'],
                    alert['target'],
                    alert['status'] == 'active' ? 'Active' : 'Inactive',
                  ];
                }).toList(),
              ),
            ];
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            );
          },
        ),
      );

      // Save the PDF
      final bytes = await pdf.save();

      // Show confirmation dialog before downloading
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.picture_as_pdf,
                          color: Colors.blue.shade700,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'PDF Report Ready',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your report has been generated. Would you like to download it now?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Generate'),
                          onPressed: () {
                            Navigator.pop(context);
                            _downloadPDF(bytes);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      // Show error message if something went wrong
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('PDF error: $e');
    }
  }

  // Method to handle the actual download
  void _downloadPDF(Uint8List bytes) {
    try {
      // For web platform, use html for downloading
      if (kIsWeb) {
        final fileName =
            'campus_alerts_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

        // Create a blob from bytes
        final blob = html.Blob([bytes], 'application/pdf');

        // Create a URL for the blob
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Create an anchor element with download attribute
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..style.display = 'none';

        // Add anchor to the body
        html.document.body?.children.add(anchor);

        // Trigger download and remove anchor
        anchor.click();
        html.document.body?.children.remove(anchor);

        // Release the object URL
        html.Url.revokeObjectUrl(url);

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF report downloaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Mobile file handling approach
        _handleMobileDownload(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('PDF download error: $e');
    }
  }

  // Helper method for mobile download
  Future<void> _handleMobileDownload(Uint8List bytes) async {
    try {
      // Get the app's documents directory to save the file
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'campus_alerts_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');

      // Write the PDF to the file
      await file.writeAsBytes(bytes);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF report saved to: ${file.path}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                OpenFile.open(file.path);
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Path error: $e');

      // Fallback: try to use a different approach with temporary directory
      try {
        // Create a simple path in the app's storage
        final fileName =
            'campus_alerts_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
        final directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final file = File('${directory.path}/$fileName');

        // Write the PDF to the file
        await file.writeAsBytes(bytes);

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF report saved to Downloads folder: $fileName'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () {
                  OpenFile.open(file.path);
                },
              ),
            ),
          );
        }
      } catch (fallbackError) {
        print('Fallback error: $fallbackError');
        if (mounted) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Could not save PDF. Please restart the app and try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Helper method to get the filtered query (not stream) for reports
  Query _getFilteredAlertsQuery() {
    Query query = FirebaseFirestore.instance.collection('alerts_data');

    // Apply date filters
    if (_selectedDateFilter != 'All') {
      DateTime now = DateTime.now();
      DateTime startDate;
      DateTime endDate;

      switch (_selectedDateFilter) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          endDate = now;
          break;
        case 'Yesterday':
          startDate = DateTime(now.year, now.month, now.day - 1);
          endDate = DateTime(now.year, now.month, now.day)
              .subtract(const Duration(milliseconds: 1));
          break;
        case 'Last Week':
          startDate = DateTime(now.year, now.month, now.day - 7);
          endDate = now;
          break;
        case 'Last Month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          endDate = now;
          break;
        case 'Custom':
          if (_customStartDate != null && _customEndDate != null) {
            startDate = _customStartDate!;
            endDate = _customEndDate!
                .add(const Duration(days: 1))
                .subtract(const Duration(milliseconds: 1));
          } else {
            return query.orderBy('timestamp', descending: true);
          }
          break;
        default: // 'All'
          return query.orderBy('timestamp', descending: true);
      }

      return query
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true);
    }

    // Default to showing all alerts
    return query.orderBy('timestamp', descending: true);
  }

  Future<Map<String, int>> _getDetailedTargetCount(String target) async {
    try {
      int students = 0;
      int faculty = 0;

      if (target == 'all' || target == 'student') {
        final studentQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('userType', isEqualTo: 'Student')
            .get();
        students = studentQuery.docs.length;
      }

      if (target == 'all' || target == 'facultyStaff') {
        final facultyQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('userType', isEqualTo: 'Faculty & Staff')
            .get();
        faculty = facultyQuery.docs.length;
      }

      return {'students': students, 'faculty': faculty};
    } catch (e) {
      print('Error getting detailed target count: $e');
      return {'students': 0, 'faculty': 0};
    }
  }
}
