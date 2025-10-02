import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // enable image picker for profile selection
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/add_security_guard_services.dart';
import '../services/audit_wrapper.dart';
import '../otp_provider/otp_provider_factory.dart';
import '../otp_provider/otp_provider.dart';
import '../otp_provider/local_verifier.dart';

// Local theme color used across admin pages
const Color kPrimaryColor = Color(0xFF1A1851);

class AddSecurityGuardUi extends StatefulWidget {
  const AddSecurityGuardUi({super.key});

  @override
  _AddSecurityGuardUiState createState() => _AddSecurityGuardUiState();
}

class _AddSecurityGuardUiState extends State<AddSecurityGuardUi> {
  // Controllers for guard detail editing
  // (Form controllers removed as add dialog is not currently implemented)

  // image bytes selected for profile
  Uint8List? _profileImageData;
  String? _profileImageName;

  // transient loading state used when sending OTP
  bool _isSendingOtp = false;
  // transient loading state used when verifying OTP
  bool _isVerifying = false;
  // Resend cooldown timer
  int _resendRemaining = 0;
  Timer? _resendTimer;

  // Local OTP verifier for Semaphore (since it doesn't have verification endpoint)
  final LocalOtpVerifier _otpVerifier = LocalOtpVerifier();

  // Send OTP to the provided phone using Node.js server. Returns SendResult for OTP code access.
  Future<SendResult?> _sendOtpToPhone(String phone, {int expire = 600}) async {
    // Create Semaphore client (no API key needed - server handles it)
    final otpProvider =
        OtpProviderFactory.createSemaphoreProvider(apiKey: 'dummy');

    try {
      final result = await otpProvider.sendOtp(
        phone: phone,
        message: 'placeholder', // Server generates the message
        expireSeconds: expire,
      );

      // Debug: Print result details
      print(
          'DEBUG: OTP Send Result - success: ${result.success}, message: ${result.message}');

      // Do not log or display the OTP. Use only status/message for UX.
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('OTP sent successfully')),
          ]),
          backgroundColor: Colors.green.shade600,
        ));
        return result; // Return the result so caller can access the OTP code
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send OTP: ${result.message}'),
          backgroundColor: Colors.red.shade600,
        ));
        return null;
      }
    } catch (e) {
      // Debug: Print exception details
      print('DEBUG: OTP Send Exception - type: ${e.runtimeType}, message: $e');

      if (e is ProviderException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('SMS service error: ${e.message}'),
          backgroundColor: Colors.red.shade600,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error sending OTP: $e'),
          backgroundColor: Colors.red.shade600,
        ));
      }
      return null;
    } finally {
      otpProvider.dispose();
    }
  }

  // Image picker helper - allows selecting an image and storing bytes
  Future<void> _pickImage({Function? onUpdate}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _profileImageData = file.bytes;
            _profileImageName = file.name;
          });
          if (onUpdate != null) {
            onUpdate(() {});
          }
        }
      }
    } catch (e) {
      // ignore errors for now; in production consider logging
    }
  }

  // Removed _buildFormCard method as it's not used in current implementation

  // Removed _showAddDialog method as it's not used in current implementation

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
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStatisticsCards(),
                const SizedBox(height: 24),
                _buildGuardsContainer(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.security,
                color: Colors.blue,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Security Guards',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
        const Row(
          children: [
            // Future: Add export button here like the PDF button in alcohol detection
            // _buildExportButton(),
            // const SizedBox(width: 16),
            // _buildFilterButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticsCards() {
    return Row(
      children: [
        _buildStatCard(
          'Total Guards',
          stream: FirebaseFirestore.instance
              .collection('securityGuard_user')
              .snapshots(),
          icon: Icons.people,
          color: const Color(0xFF4285F4),
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Verified Guards',
          stream: FirebaseFirestore.instance
              .collection('securityGuard_user')
              .snapshots(),
          icon: Icons.verified_user,
          color: const Color(0xFF0F9D58),
          statusFilter: 'verified',
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Pending Verification',
          stream: FirebaseFirestore.instance
              .collection('securityGuard_user')
              .snapshots(),
          icon: Icons.pending,
          color: const Color(0xFFFF9800),
          statusFilter: 'pending',
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title, {
    required Stream<QuerySnapshot> stream,
    required IconData icon,
    required Color color,
    String? statusFilter,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                    'Error',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text(
                    '...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  );
                }

                int count = 0;
                if (snapshot.data != null) {
                  if (statusFilter != null) {
                    count = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final isVerified = data['isVerifiedByAdmin'] == true ||
                          data['emailVerified'] == true;
                      if (statusFilter == 'verified') {
                        return isVerified;
                      } else if (statusFilter == 'pending') {
                        return !isVerified;
                      }
                      return false;
                    }).length;
                  } else {
                    count = snapshot.data!.docs.length;
                  }
                }

                return Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardsContainer() {
    return Container(
      height: 600,
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
          _buildGuardsHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildGuardsTable(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardsHeader() {
    return Container(
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
              Icon(Icons.list_alt, size: 24, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Text(
                'Guards List',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('securityGuard_user')
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.size : 0;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Text(
                  '$count entries',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGuardsTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('securityGuard_user')
          .orderBy('accountCreated', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return _buildDataTable(docs);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No security guards found',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<QueryDocumentSnapshot> guards) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.grey.shade200,
            dataTableTheme: DataTableTheme.of(context).copyWith(
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: 24,
                    headingRowColor:
                        WidgetStateProperty.all(Colors.grey.shade50),
                    dataRowHeight: 64,
                    headingRowHeight: 56,
                    horizontalMargin: 16,
                    showCheckboxColumn: false,
                    dividerThickness: 1,
                    columns: const [
                      DataColumn(
                          label: Text('Email',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Created',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Status',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Actions',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: guards.map((doc) => _buildDataRow(doc)).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final email = data['email'] ?? '';
    final ts = data['accountCreated'];
    String createdStr = '';
    if (ts is Timestamp) {
      createdStr = DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate());
    } else if (ts is int) {
      createdStr = DateFormat('dd/MM/yyyy HH:mm')
          .format(DateTime.fromMillisecondsSinceEpoch(ts));
    }

    final isVerified =
        data['isVerifiedByAdmin'] == true || data['emailVerified'] == true;
    final imgUrl = data['profileImageUrl'] ?? '';

    return DataRow(
      onSelectChanged: (selected) {
        if (selected ?? false) {
          _showGuardDetails(data, imgUrl, doc.id);
        }
      },
      cells: [
        _buildDataCell(Icons.email, email),
        _buildDataCell(Icons.calendar_today, createdStr),
        DataCell(_buildStatusChip(isVerified ? 'verified' : 'pending')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isVerified)
                TextButton(
                  onPressed: () => _verifyGuard(doc.id),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    minimumSize: const Size(72, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Verify'),
                ),
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () => _showGuardDetails(data, imgUrl, doc.id),
                tooltip: 'View Details',
                color: Colors.blue,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              // Three-dot menu for more actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) async {
                  if (value == 'disable') {
                    // Show confirmation dialog for disable
                    final confirmed = await _showConfirmationDialog(
                      title: 'Confirm Disable',
                      message:
                          'Are you sure you want to disable this guard? They will no longer have access to the system.',
                      actionButtonText: 'Disable',
                      actionButtonColor: Colors.orange,
                    );

                    if (confirmed) {
                      await disableGuard(doc.id); // Call stub from service
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Disable action triggered (not implemented)')),
                        );
                      }
                    }
                  } else if (value == 'delete') {
                    // Show confirmation dialog for delete
                    final confirmed = await _showConfirmationDialog(
                      title: 'Confirm Delete',
                      message:
                          'Are you sure you want to delete this guard? This action cannot be undone.',
                      actionButtonText: 'Delete',
                      actionButtonColor: Colors.red,
                    );

                    if (confirmed) {
                      await deleteGuard(doc.id); // Call stub from service
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Delete action triggered (not implemented)')),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'disable',
                    child: ListTile(
                      leading: Icon(Icons.block, color: Colors.orange),
                      title: Text('Disable'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  DataCell _buildDataCell(IconData icon, String text) {
    return DataCell(
      Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    IconData statusIcon;
    String displayText;

    switch (status.toLowerCase()) {
      case 'verified':
        chipColor = Colors.green;
        statusIcon = Icons.check_circle;
        displayText = 'VERIFIED';
        break;
      case 'pending':
        chipColor = Colors.orange;
        statusIcon = Icons.pending;
        displayText = 'PENDING';
        break;
      default:
        chipColor = Colors.grey;
        statusIcon = Icons.help_outline;
        displayText = 'UNKNOWN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: chipColor),
          const SizedBox(width: 6),
          Text(
            displayText,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showGuardDetails(Map<String, dynamic> data, String imageUrl,
      [String? docId]) async {
    // local controllers for editable fields in the dialog
    final TextEditingController nameController =
        TextEditingController(text: (data['name'] ?? '').toString());
    final TextEditingController phoneController =
        TextEditingController(text: (data['phone'] ?? '').toString());

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: SizedBox(
              width: double.infinity,
              // Use a Column with a scrollable, flexible content area to avoid overflow
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.blue, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text('Guard Details',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Flexible scrollable area for the main content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Decorative avatar with subtle gradient ring
                          Center(
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade200,
                                    Colors.purple.shade100
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: ClipOval(
                                  child: _profileImageData != null
                                      ? Image.memory(
                                          _profileImageData!,
                                          width: 118,
                                          height: 118,
                                          fit: BoxFit.cover,
                                        )
                                      : (imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              width: 118,
                                              height: 118,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) =>
                                                  Container(
                                                width: 118,
                                                height: 118,
                                                color: Colors.grey.shade100,
                                                child: const Icon(Icons.person,
                                                    size: 44),
                                              ),
                                            )
                                          : Container(
                                              width: 118,
                                              height: 118,
                                              color: Colors.grey.shade100,
                                              child: const Icon(Icons.person,
                                                  size: 44),
                                            )),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _pickImage(onUpdate: setDialogState),
                                  icon: const Icon(Icons.photo),
                                  label: const Text('Change Photo'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                if (_profileImageData != null)
                                  OutlinedButton(
                                    onPressed: () {
                                      setDialogState(() {
                                        _profileImageData = null;
                                        _profileImageName = null;
                                      });
                                    },
                                    child: const Text('Remove'),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Form card with subtle elevation and rounded corners
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Profile',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full name',
                                    prefixIcon: const Icon(Icons.person),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: phoneController,
                                  decoration: InputDecoration(
                                    labelText: 'Phone',
                                    prefixIcon: const Icon(Icons.phone),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  readOnly: true,
                                  initialValue: data['email'] ?? 'N/A',
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.email),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatAccountCreatedForDisplay(
                                              data['accountCreated']) ??
                                          'N/A',
                                      style: TextStyle(
                                          color: Colors.grey.shade700),
                                    ),
                                    const Spacer(),
                                    _buildStatusChip(
                                        (data['isVerifiedByAdmin'] == true ||
                                                data['emailVerified'] == true)
                                            ? 'verified'
                                            : 'pending'),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Actions pinned to bottom
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!(data['isVerifiedByAdmin'] == true ||
                            data['emailVerified'] == true))
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _verifyGuard(
                                  data['uid'] ?? docIdFromData(data));
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white),
                            child: const Text('Verify'),
                          ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            // perform save with OTP verification flow
                            final targetDocId =
                                data['uid'] ?? docIdFromData(data);
                            final newName = nameController.text.trim();
                            final newPhone = phoneController.text.trim();
                            await _saveWithOtpFlow(targetDocId,
                                name: newName, phone: newPhone);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save Changes'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Extract document id from data if present under common keys
  String docIdFromData(Map<String, dynamic> data) {
    if (data.containsKey('docId')) return data['docId']?.toString() ?? '';
    if (data.containsKey('id')) return data['id']?.toString() ?? '';
    if (data.containsKey('uid')) return data['uid']?.toString() ?? '';
    return '';
  }

  // Verify guard by document id using service and show SnackBar result
  Future<void> _verifyGuard(String docId) async {
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Unable to verify: missing document id'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final success = await verifyGuard(docId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(success ? Icons.check_circle : Icons.error_outline,
              color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
              child: Text(success
                  ? 'Guard verified successfully'
                  : 'Failed to verify guard')),
        ]),
        backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ));

      // Log successful guard verification
      if (success) {
        await AuditWrapper.instance.logGuardVerified();
      }
    }
  }

  // Upload selected image (if any) and save changes to guard document
  Future<void> _saveGuardChanges(String docId,
      {String? name, String? phone, bool markPhoneVerified = false}) async {
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Unable to save: missing document id'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Show loading snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 12),
          Expanded(child: Text('Saving changes...')),
        ]),
        duration: Duration(minutes: 1),
      ));
    }

    String? uploadedUrl;
    try {
      if (_profileImageData != null && _profileImageName != null) {
        final resp = await uploadImage(_profileImageData!, _profileImageName!);
        uploadedUrl = resp['secure_url'] as String?;
      }

      final updates = <String, dynamic>{};
      if (uploadedUrl != null) updates['profileImageUrl'] = uploadedUrl;
      if (name != null && name.isNotEmpty) updates['name'] = name;
      if (phone != null && phone.isNotEmpty) updates['phone'] = phone;
      if (markPhoneVerified) updates['isPhoneNumberVerified'] = true;

      final success = await updateGuard(docId, updates);

      ScaffoldMessenger.of(context).clearSnackBars();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Icon(success ? Icons.check_circle : Icons.error_outline,
                color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
                child: Text(success
                    ? 'Changes saved successfully'
                    : 'Failed to save changes')),
          ]),
          backgroundColor:
              success ? Colors.green.shade600 : Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ));

        // Log successful guard profile update
        if (success) {
          await AuditWrapper.instance.logGuardProfileUpdated();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Error saving changes: $e')),
          ]),
          backgroundColor: Colors.red.shade600,
        ));
      }
    }
  }

  // Send OTP to `phone`, prompt admin to input OTP, verify it, then save changes.
  Future<void> _saveWithOtpFlow(String docId,
      {String? name, String? phone}) async {
    if (phone == null || phone.isEmpty) {
      // If phone not provided, just save normally
      await _saveGuardChanges(docId, name: name, phone: phone);
      return;
    }

    // Check existing guard document for phone verification status
    try {
      final docRef = FirebaseFirestore.instance
          .collection('securityGuard_user')
          .doc(docId);
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        final currentPhone = snapshot.data()?['phone']?.toString() ?? '';
        final isVerified = snapshot.data()?['isPhoneNumberVerified'] == true;
        // If phone hasn't changed and is already verified, skip OTP flow
        if (isVerified && currentPhone == phone) {
          await _saveGuardChanges(docId,
              name: name, phone: phone, markPhoneVerified: true);
          return;
        }
        // If phone changed, clear the verification flag so we can reverify
        if (currentPhone != phone && isVerified) {
          await updateGuard(docId, {'isPhoneNumberVerified': false});
        }
      }
    } catch (e) {
      // If Firestore read fails, continue to OTP flow (fail-open)
    }

    // Send OTP
    setState(() => _isSendingOtp = true);
    SendResult? sendResult;
    try {
      sendResult = await _sendOtpToPhone(phone, expire: 600);

      // Store OTP for local verification if send was successful
      if (sendResult != null && sendResult.success && sendResult.code != null) {
        print('DEBUG: Storing OTP code for verification: ${sendResult.code!}');
        await _otpVerifier.storeOtp(
          phone: phone,
          code: sendResult.code!,
          ttlSeconds: 600, // 10 minutes
        );
      }
    } finally {
      setState(() => _isSendingOtp = false);
    }

    // If OTP send failed, don't proceed to verification dialog
    if (sendResult == null || !sendResult.success) {
      return;
    }

    // Prompt admin to enter OTP
    final otpController = TextEditingController();
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'An OTP was sent to the provided phone. Enter it to verify.'),
            const SizedBox(height: 12),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'OTP'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: (_resendRemaining > 0 || _isSendingOtp)
                ? null
                : () async {
                    // Resend OTP with cooldown
                    setState(() {
                      _isSendingOtp = true;
                      _resendRemaining = 30;
                    });
                    _resendTimer?.cancel();
                    _resendTimer =
                        Timer.periodic(const Duration(seconds: 1), (t) {
                      setState(() {
                        _resendRemaining = _resendRemaining - 1;
                        if (_resendRemaining <= 0) {
                          t.cancel();
                        }
                      });
                    });
                    try {
                      await _sendOtpToPhone(phone, expire: 600);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('OTP resent'),
                      ));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Failed to resend OTP: $e'),
                        backgroundColor: Colors.red.shade600,
                      ));
                    } finally {
                      setState(() => _isSendingOtp = false);
                    }
                  },
            child: _isSendingOtp
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : (_resendRemaining > 0
                    ? Text('Resend ($_resendRemaining)')
                    : const Text('Resend')),
          ),
          ElevatedButton(
            onPressed: _isVerifying
                ? null
                : () async {
                    final otp = otpController.text.trim();
                    if (otp.isEmpty) return;
                    setState(() => _isVerifying = true);

                    try {
                      // Debug: Log what OTP user entered vs what we expect
                      print('DEBUG: User entered OTP: $otp');
                      print(
                          'DEBUG: Verifying against stored OTP for phone: $phone');

                      // First try normal verification
                      final verifyResult = await _otpVerifier.verifyOtp(
                        phone: phone,
                        code: otp,
                      );

                      print(
                          'DEBUG: Verification result: ${verifyResult.verified}, message: ${verifyResult.message}');

                      if (verifyResult.verified) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('OTP verified successfully!'),
                          backgroundColor: Colors.green,
                        ));
                        Navigator.pop(context, true);
                      } else {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(verifyResult.message),
                          backgroundColor: Colors.red,
                        ));
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Error verifying OTP: $e'),
                        backgroundColor: Colors.red.shade600,
                      ));
                    } finally {
                      setState(() => _isVerifying = false);
                    }
                  },
            child: _isVerifying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verify'),
          ),
        ],
      ),
    );

    if (verified == true) {
      // proceed to save
      await _saveGuardChanges(docId,
          name: name, phone: phone, markPhoneVerified: true);
    } else {
      // do nothing; admin cancelled or verification failed
    }
  }

  // Helper to format accountCreated field which may be Timestamp, int (ms since epoch), or String
  String? _formatAccountCreatedForDisplay(dynamic raw) {
    if (raw == null) return null;

    DateTime? dt;
    try {
      if (raw is Timestamp) {
        dt = raw.toDate();
      } else if (raw is int) {
        // assume milliseconds since epoch
        dt = DateTime.fromMillisecondsSinceEpoch(raw);
      } else if (raw is String) {
        // attempt to parse common string formats
        dt = DateTime.tryParse(raw);
      }
    } catch (_) {
      dt = null;
    }

    if (dt == null) return null;

    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  // Reusable confirmation dialog for actions like disable/delete
  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String actionButtonText,
    required Color actionButtonColor,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              actionButtonText,
              style: TextStyle(color: actionButtonColor),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}
