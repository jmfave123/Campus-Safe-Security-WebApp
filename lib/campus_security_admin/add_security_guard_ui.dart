import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // enable image picker for profile selection
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/add_security_guard_services.dart';

// Local theme color used across admin pages
const Color kPrimaryColor = Color(0xFF1A1851);

class AddSecurityGuardUi extends StatefulWidget {
  const AddSecurityGuardUi({Key? key}) : super(key: key);

  @override
  _AddSecurityGuardUiState createState() => _AddSecurityGuardUiState();
}

class _AddSecurityGuardUiState extends State<AddSecurityGuardUi> {
  // form state and controllers
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _badgeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // transient form fields
  String _name = '';
  String _phone = '';
  String _badge = '';

  // image bytes selected for profile
  Uint8List? _profileImageData;
  String? _profileImageName;

  // dialog context when dialogs are shown
  BuildContext? _dialogContext;

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

  // Minimal form card used in Add dialog. Keeps the original app's fields
  // but does not implement full submission here (server-side flow preferred).
  Widget _buildFormCard(void Function(void Function()) setDialogState) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _badgeController,
                decoration: const InputDecoration(labelText: 'Badge'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      _emailController.clear();
                      _passwordController.clear();
                      setDialogState(() {
                        _profileImageData = null;
                        _profileImageName = null;
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        // store dialog context so we can close it from _submit
        _dialogContext = dialogContext;
        final mq = MediaQuery.of(dialogContext).size;
        // Keep dialog compact: 90% on very small screens, otherwise cap at 420px
        final double maxDialogWidth = mq.width < 480 ? mq.width * 0.9 : 420;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              // light gray sheet behind the card (not fully transparent)
              backgroundColor: Colors.grey.shade200,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              // make the gray sheet smaller on wide screens by increasing inset
              insetPadding: EdgeInsets.symmetric(
                horizontal: mq.width < 800 ? 24.0 : mq.width * 0.18,
                vertical: mq.height < 700 ? 24.0 : mq.height * 0.12,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxDialogWidth),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile avatar & image picker
                          // Top-centered avatar with camera overlay (social-media style)
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Avatar with ring and shadow
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () =>
                                      _pickImage(onUpdate: setDialogState),
                                  child: Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _profileImageData == null
                                            ? kPrimaryColor.withOpacity(0.2)
                                            : kPrimaryColor,
                                        width: _profileImageData == null
                                            ? 1.5
                                            : 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                      color: Colors.grey.shade100,
                                    ),
                                    child: ClipOval(
                                      child: _profileImageData != null
                                          ? Image.memory(
                                              _profileImageData!,
                                              width: 84,
                                              height: 84,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: Colors.transparent,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.person,
                                                color: kPrimaryColor,
                                                size: 40,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),

                              // Camera action button (overlapping)
                              Positioned(
                                right: -4,
                                bottom: -4,
                                child: Material(
                                  color: Colors.white,
                                  elevation: 2,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () =>
                                        _pickImage(onUpdate: setDialogState),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 18,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Add Security Guard',
                            style: TextStyle(
                              color: kPrimaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // form card stretches to full constrained width
                          Align(
                            alignment: Alignment.center,
                            child: _buildFormCard(setDialogState),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // clear dialog context when it closes
      _dialogContext = null;
      // also reset form state so next open starts fresh
      _formKey.currentState?.reset();
      _name = '';
      _phone = '';
      _badge = '';
      _profileImageData = null;
      _profileImageName = null;
    });
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
        Row(
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
                  child: const Text('Verify'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    minimumSize: const Size(72, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () => _showGuardDetails(data, imgUrl, doc.id),
                tooltip: 'View Details',
                color: Colors.blue,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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

  void _showGuardDetails(Map<String, dynamic> data, String imageUrl,
      [String? docId]) {
    showDialog(
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
                          const Divider(),
                          const SizedBox(height: 8),
                          // Profile preview
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _profileImageData != null
                                  ? Image.memory(
                                      _profileImageData!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    )
                                  : (imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Container(
                                            width: 120,
                                            height: 120,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.person,
                                                size: 40),
                                          ),
                                        )
                                      : Container(
                                          width: 120,
                                          height: 120,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.person,
                                              size: 40),
                                        )),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _pickImage(onUpdate: setDialogState),
                                icon: const Icon(Icons.photo),
                                label: const Text('Select Photo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (_profileImageData != null)
                                TextButton(
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
                          const SizedBox(height: 12),
                          _buildDetailItem(
                              Icons.email, 'Email', data['email'] ?? 'N/A'),
                          _buildDetailItem(
                              Icons.calendar_today,
                              'Created',
                              _formatAccountCreatedForDisplay(
                                      data['accountCreated']) ??
                                  'N/A'),
                          _buildDetailItem(
                            Icons.verified_user,
                            'Verification Status',
                            (data['isVerifiedByAdmin'] == true ||
                                    data['emailVerified'] == true)
                                ? 'Verified'
                                : 'Pending',
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
                            Navigator.pop(context);
                            await _saveGuardChanges(
                                data['uid'] ?? docIdFromData(data));
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
    }
  }

  // Upload selected image (if any) and save changes to guard document
  Future<void> _saveGuardChanges(String docId) async {
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Unable to save: missing document id'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Show loading snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: const [
          CircularProgressIndicator(),
          SizedBox(width: 12),
          Expanded(child: Text('Saving changes...')),
        ]),
        duration: const Duration(minutes: 1),
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

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _badgeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
