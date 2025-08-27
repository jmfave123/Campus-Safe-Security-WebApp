import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/add_security_guard_services.dart';
import '../widgets/reusable_text_field.dart';

// Reuse the same primary color used in HomePage
const Color kPrimaryColor = Color(0xFF1A1851);

class AddSecurityGuardUi extends StatefulWidget {
  const AddSecurityGuardUi({super.key});

  @override
  State<AddSecurityGuardUi> createState() => _AddSecurityGuardUiState();
}

class _AddSecurityGuardUiState extends State<AddSecurityGuardUi> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phone = '';
  String _badge = '';
  BuildContext? _dialogContext;
  Uint8List? _profileImage;
  // Controllers for reusable text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _badgeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // read values from controllers
      _name = _nameController.text.trim();
      _phone = _phoneController.text.trim();
      _badge = _badgeController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      // Call service to add guard
      addSecurityGuard(
        name: _name,
        phone: _phone,
        badge: _badge,
        profileImage: _profileImage,
        email: email,
        password: password,
      ).then((_) {
        // show success and close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Security guard "$_name" added'),
            backgroundColor: kPrimaryColor,
          ),
        );
        if (_dialogContext != null) {
          Navigator.of(_dialogContext!).pop();
          _dialogContext = null;
        }
        // clear controllers after success
        _nameController.clear();
        _phoneController.clear();
        _badgeController.clear();
        _emailController.clear();
        _passwordController.clear();
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add guard: $e')),
        );
      });
    }
  }

  // Returns the card-like container with the form (extracted from the original file)
  Widget _buildFormCard([StateSetter? onDialogUpdate]) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            reusableTextField(
              controller: _nameController,
              labelText: 'Full Name',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a name'
                  : null,
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 12),
            reusableTextField(
              controller: _phoneController,
              labelText: 'Phone Number',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a phone number'
                  : null,
            ),
            const SizedBox(height: 12),
            reusableTextField(
              controller: _badgeController,
              labelText: 'Badge / ID',
              prefixIcon: Icons.badge,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter badge or ID'
                  : null,
            ),
            const SizedBox(height: 12),
            reusableTextField(
              controller: _emailController,
              labelText: 'Email',
              prefixIcon: Icons.email,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter an email'
                  : null,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            reusableTextField(
              controller: _passwordController,
              labelText: 'Password',
              prefixIcon: Icons.lock,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a password'
                  : null,
              obscureText: true,
              showToggle: true,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Text('Add Guard'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    _formKey.currentState?.reset();
                    setState(() {
                      _name = '';
                      _phone = '';
                      _badge = '';
                      _profileImage = null;
                    });
                    // also clear controllers
                    _nameController.clear();
                    _phoneController.clear();
                    _badgeController.clear();
                    _emailController.clear();
                    _passwordController.clear();
                    if (onDialogUpdate != null) onDialogUpdate(() {});
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimaryColor,
                    side: BorderSide(color: kPrimaryColor.withOpacity(0.2)),
                  ),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Text('Reset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage({Function? onUpdate}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        // Prefer bytes (web); if not available (desktop) try path as fallback
        if (file.bytes != null) {
          setState(() {
            _profileImage = file.bytes;
          });
          // Call dialog update function if provided
          if (onUpdate != null) {
            onUpdate(() {});
          }
        } else if (file.path != null) {
          // On some platforms FilePicker returns a path but not bytes.
          // We don't show debug UI here; production code might handle path-based loading.
        }
      }
    } catch (e) {
      // ignore errors for now; in production consider logging
    }
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
                                        color: _profileImage == null
                                            ? kPrimaryColor.withOpacity(0.2)
                                            : kPrimaryColor,
                                        width:
                                            _profileImage == null ? 1.5 : 2.5,
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
                                      child: _profileImage != null
                                          ? Image.memory(
                                              _profileImage!,
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
      _profileImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.security, color: kPrimaryColor),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add Security Guard',
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Right aligned + Add button
                  ElevatedButton.icon(
                    onPressed: _showAddDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                      child: Text('Add'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Placeholder space - form is shown in the popup when + Add is pressed
              Expanded(
                child: Center(
                  child: Text(
                    'Press + Add to add a new security guard',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
