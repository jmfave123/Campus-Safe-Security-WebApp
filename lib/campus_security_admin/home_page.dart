// ignore_for_file: avoid_print, unused_element, invalid_use_of_protected_member, unused_local_variable, avoid_types_as_parameter_names, unnecessary_brace_in_string_interps

import 'package:campus_safe_app_admin_capstone/audit_logs/audit_ui.dart';
import 'package:campus_safe_app_admin_capstone/campus_security_admin/admin_dashboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../reusable_widget.dart';
import 'add_security_guard_ui.dart';
import '../services/audit_wrapper.dart';
import '../services/web_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'alcohol_detection_page.dart';
import 'campus_security_admin_login.dart';
import 'reports_screen.dart';
import 'throw_alerts.dart';
import 'search_account.dart';
import 'user_logs.dart';
import 'settings_page.dart';
import 'gemini_chat_page.dart';

// USTP palette
const Color kPrimaryColor = Color(0xFF1A1851); // deep indigo
const Color kAccentColor = Color(0xFFFBB215); // warm yellow

// Previous blues commented for reference:
// Colors.blue
// Colors.blue.shade700
// Colors.blue.shade400
// Colors.blue.shade200
// Colors.blue.shade50

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  OverlayEntry? _overlayEntry;
  bool _isNotificationOpen = false;
  int _unreadNotificationCount = 0;

  static final List<Widget> _pages = <Widget>[
    const AdminDashboard(),
    const AlcoholDetectionPage(),
    const ThrowAlertsPage(),
    const SearchAccountPage(),
    const UserLogsPage(),
    const ReportsScreen(),
    const GeminiChatPage(),
    const AuditUi(),
    const SettingsPage(),
    const AddSecurityGuardUi(),
    // const LogoutPage(),
  ];

  @override
  void initState() {
    super.initState();
    // Check authentication status
    _checkAuth();
    // Get initial unread notification count
    _fetchUnreadNotificationCount();

    // Set up a listener for real-time notification updates
    _setupNotificationListener();
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _redirectToLogin();
      return;
    }

    try {
      // Add a small delay to ensure Firebase Auth operation is complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Try the campus_security_admin collection first with timeout
      try {
        final adminDoc = await FirebaseFirestore.instance
            .collection('campus_security_admin')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5));

        if (adminDoc.exists) {
          // Show success dialog
          _showLoginSuccessDialog();
          return; // User is admin, continue with the app
        }
      } catch (e) {
        print('Error checking campus_security_admin: $e');
        // Continue to next check instead of immediately failing
      }

      // Add another small delay before next Firestore operation
      await Future.delayed(const Duration(milliseconds: 300));

      // If first check fails or document doesn't exist, try admin_users collection
      try {
        final adminUserDoc = await FirebaseFirestore.instance
            .collection('admin_users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5));

        if (adminUserDoc.exists && adminUserDoc.data()?['isAdmin'] == true) {
          // Show success dialog
          _showLoginSuccessDialog();
          return; // User is admin, continue with the app
        }
      } catch (e) {
        print('Error checking admin_users: $e');
        // Continue to query-based approach
      }

      // If both direct document approaches fail, try a query-based approach
      try {
        // Add a delay before trying a different query approach
        await Future.delayed(const Duration(milliseconds: 300));

        final adminQueryResult = await FirebaseFirestore.instance
            .collection('admin_users')
            .where(FieldPath.documentId, isEqualTo: user.uid)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 5));

        if (adminQueryResult.docs.isNotEmpty &&
            adminQueryResult.docs.first.data()['isAdmin'] == true) {
          // Show success dialog
          _showLoginSuccessDialog();
          return; // User is admin, continue with the app
        }
      } catch (e) {
        print('Error with admin query: $e');
        // Fall through to logout if all checks fail
      }

      // If we get here, user is not verified as an admin
      print('User not verified as admin, logging out');
      await FirebaseAuth.instance.signOut();
      _redirectToLogin();
    } catch (e) {
      print('Error checking admin status: $e');
      _redirectToLogin();
    }
  }

  // Show login success dialog
  void _showLoginSuccessDialog() {
    if (!mounted) return;

    buildSuccessDialog(
      context: context,
      title: 'Logged in Successfully',
      message: 'Welcome to Campus Security Admin',
      buttonText: 'Continue',
      onButtonPressed: () {
        Navigator.of(context).pop();
      },
      icon: Icons.check_circle_outline,
      gradientColors: [kPrimaryColor, kPrimaryColor],
      // previous: [Colors.blue.shade400, Colors.blue.shade700]
      delayMilliseconds: 300,
    );
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginForm()),
    );
  }

  Future<void> _logout() async {
    // Show confirmation dialog first
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 280, // Set a fixed width to make dialog narrower
            padding: const EdgeInsets.all(16), // Reduced padding
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kPrimaryColor.withOpacity(0.6), kPrimaryColor],
              ),
              // previous gradient: [Colors.blue.shade400, Colors.blue.shade700]
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withOpacity(0.12),
                  // previous: Colors.blue.shade200.withOpacity(0.5)
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 50, // Reduced icon size
                ),
                const SizedBox(height: 12), // Reduced spacing
                const Text(
                  'Confirm Logout',
                  style: TextStyle(
                    fontSize: 18, // Reduced font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8), // Reduced spacing
                const Text(
                  'Are you sure you want to logout?',
                  style: TextStyle(
                    fontSize: 14, // Reduced font size
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16), // Reduced spacing
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // No button
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8), // Reduced padding
                      ),
                      child: const Text(
                        'No',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Yes button
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop(); // Close dialog
                        try {
                          await FirebaseAuth.instance.signOut();

                          if (!mounted) return;

                          // Directly redirect to login page without showing success dialog
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => const LoginForm()),
                          );
                        } catch (e) {
                          print('Error signing out: $e');
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8), // Reduced padding
                      ),
                      child: const Text(
                        'Yes',
                        style: TextStyle(
                          color: kPrimaryColor,
                          // previous: Colors.blue.shade700
                          fontWeight: FontWeight.bold,
                        ),
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

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isNotificationOpen = false;
      });
    }
  }

  void _toggleNotificationPanel(
      BuildContext context, GlobalKey notificationKey) async {
    // Request web notification permission if on web and not granted
    if (kIsWeb) {
      try {
        final hasPermission = await WebNotificationService.areNotificationsEnabled();
        if (!hasPermission) {
          await _requestWebNotificationPermission();
        }
      } catch (e) {
        print('Error checking notification permission: $e');
      }
    }

    if (_isNotificationOpen) {
      _removeOverlay();
      return;
    }

    // Find the position of the notification icon
    final RenderBox renderBox =
        notificationKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy + size.height + 8,
        right: 20,
        width: 350,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          child: NotificationPanel(
            onClose: _removeOverlay,
            onMarkAllRead: _markAllNotificationsAsRead,
            onNavigateToReports: navigateToReportsTab,
            onNavigateToAlcoholDetection: navigateToAlcoholDetectionTab,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isNotificationOpen = true;
    });
  }

  Future<void> _markAllNotificationsAsRead() async {
    try {
      // Create batch update
      final batch = FirebaseFirestore.instance.batch();

      // Get unread notifications from notification_to_admin
      final QuerySnapshot unreadAdminNotifications = await FirebaseFirestore
          .instance
          .collection('notification_to_admin')
          .where('isRead', isEqualTo: false)
          .get();

      // Add each unread notification to batch
      for (var doc in unreadAdminNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Get unread notifications from notification_from_breatheanalyzer
      final QuerySnapshot unreadBreatheanalyzerNotifications =
          await FirebaseFirestore.instance
              .collection('notification_from_breatheanalyzer')
              .where('status', isEqualTo: 'unread')
              .get();

      // Add each unread breathalyzer notification to batch
      for (var doc in unreadBreatheanalyzerNotifications.docs) {
        batch.update(doc.reference, {'status': 'read'});
      }

      // Commit batch
      await batch.commit();

      // Update UI
      if (mounted) {
        setState(() {
          _unreadNotificationCount = 0;
        });
      }

      // Close notification panel
      _removeOverlay();
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  // Setup a real-time listener for new notifications
  void _setupNotificationListener() {
    // Listen to notification_to_admin collection
    FirebaseFirestore.instance
        .collection('notification_to_admin')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _unreadNotificationCount = snapshot.docs.length;
        });
      }
    }, onError: (error) {
      print('Error listening to notifications: $error');
    });

    // Listen to notification_from_breatheanalyzer collection
    FirebaseFirestore.instance
        .collection('notification_from_breatheanalyzer')
        .where('status', isEqualTo: 'unread')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          // Add these notifications to the existing count
          _unreadNotificationCount += snapshot.docs.length;
        });
      }
    }, onError: (error) {
      print('Error listening to breathalyzer notifications: $error');
    });
  }

  // Request web notification permission
  Future<void> _requestWebNotificationPermission() async {
    if (!kIsWeb) return;

    try {
      final hasPermission = await WebNotificationService.areNotificationsEnabled();
      
      if (!hasPermission) {
        // Show a friendly dialog before requesting permission
        final shouldRequest = await _showPermissionDialog();
        
        if (shouldRequest == true) {
          // Try OneSignal first
          bool granted = await WebNotificationService.requestPermission();
          
          // If OneSignal fails, try native browser API
          if (!granted) {
            print('OneSignal permission failed, trying native API...');
            granted = await WebNotificationService.requestNativePermission();
          }
          
          if (granted) {
            _showNotificationSuccessSnackBar();
          } else {
            _showNotificationDeniedSnackBar();
          }
        }
      }
    } catch (e) {
      print('Error requesting web notification permission: $e');
      _showNotificationDeniedSnackBar();
    }
  }

  // Show permission request dialog
  Future<bool?> _showPermissionDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Make it modal
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.notifications_active, color: kPrimaryColor),
              const SizedBox(width: 8),
              const Text('Enable Notifications'),
            ],
          ),
          content: const Text(
            'Would you like to receive push notifications for:\n\n'
            '• New incident reports\n'
            '• Security alerts and announcements\n'
            '• Alcohol detection warnings\n'
            '• Important system updates\n\n'
            'You can change this setting later in your browser.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enable Notifications'),
            ),
          ],
        );
      },
    );
  }

  // Show success message
  void _showNotificationSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Notifications enabled successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show denied message
  void _showNotificationDeniedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            const Text('You can enable notifications later in browser settings.'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Fetch the initial count of unread notifications
  Future<void> _fetchUnreadNotificationCount() async {
    try {
      int totalUnreadCount = 0;

      // Count unread notifications from notification_to_admin
      final QuerySnapshot adminNotifications = await FirebaseFirestore.instance
          .collection('notification_to_admin')
          .where('isRead', isEqualTo: false)
          .get();

      totalUnreadCount += adminNotifications.docs.length;

      // Count unread notifications from notification_from_breatheanalyzer
      final QuerySnapshot breathalyzerNotifications = await FirebaseFirestore
          .instance
          .collection('notification_from_breatheanalyzer')
          .where('status', isEqualTo: 'unread')
          .get();

      totalUnreadCount += breathalyzerNotifications.docs.length;

      if (mounted) {
        setState(() {
          _unreadNotificationCount = totalUnreadCount;
        });
      }
    } catch (e) {
      print('Error fetching unread notifications: $e');
    }
  }

  // Method to navigate to the Reports tab
  void navigateToReportsTab() {
    setState(() {
      _selectedIndex = 5;
    });
  }

  // Method to navigate to the Alcohol Detection tab
  void navigateToAlcoholDetectionTab() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  // Public method to allow other widgets to change the tab
  void navigateToTab(int tabIndex) {
    setState(() {
      _selectedIndex = tabIndex;
    });
  }

  Widget buildNavItem(int index, String title, IconData icon,
      {required bool isSelected, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? kPrimaryColor.withOpacity(0.1) : Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? kPrimaryColor : Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? kPrimaryColor : Colors.grey.shade700,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey notificationKey = GlobalKey();

    return GestureDetector(
      // Close notification panel when clicking outside
      onTap: () {
        if (_isNotificationOpen) {
          _removeOverlay();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            // Custom App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              decoration: boxDecoration(
                  Colors.white, Colors.grey, 1, 8, const Offset(0, 2)),
              child: Row(
                children: [
                  rowWidget(8, Colors.blue, 0.1, 8, Icons.shield_outlined, 24,
                      'Campus Security', FontWeight.bold),
                  const Spacer(),
                  // Profile Section in header
                  Row(
                    children: [
                      // Notification Bell Icon with Badge
                      Stack(
                        key: notificationKey,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isNotificationOpen
                                  ? kPrimaryColor.withOpacity(0.08)
                                  : Colors.grey.shade100,
                              // previous: Colors.blue.withOpacity(0.1)
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_outlined),
                              color: _isNotificationOpen
                                  ? kPrimaryColor
                                  : kPrimaryColor.withOpacity(0.95),
                              // previous: Colors.blue / Colors.blue.shade700
                              onPressed: () {
                                _toggleNotificationPanel(
                                    context, notificationKey);
                              },
                              tooltip: 'Notifications',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          if (_unreadNotificationCount > 0)
                            Positioned(
                              right: 5,
                              top: 5,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  _unreadNotificationCount > 99
                                      ? '99+'
                                      : _unreadNotificationCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // User profile icon with popup menu
                      PopupMenuButton<String>(
                        offset: const Offset(0, 40),
                        onSelected: (String value) {
                          if (value == 'profile') {
                            // Handle profile navigation
                          } else if (value == 'logout') {
                            _logout();
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.account_circle, size: 18),
                                SizedBox(width: 8),
                                Text('Profile'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, size: 18),
                                SizedBox(width: 8),
                                Text('Logout'),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kPrimaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryColor.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: kPrimaryColor,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            // Main Content Area
            Expanded(
              child: Row(
                children: [
                  // Navigation Sidebar
                  Container(
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 6,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      children: [
                        buildNavItem(0, 'Dashboard', Icons.dashboard_outlined,
                            isSelected: _selectedIndex == 0, onTap: () {
                          setState(() => _selectedIndex = 0);
                          AuditWrapper.instance.logPageAccess(0);
                        }),
                        buildNavItem(
                            1, 'Alcohol Detection', Icons.local_drink_outlined,
                            isSelected: _selectedIndex == 1, onTap: () {
                          setState(() => _selectedIndex = 1);
                          AuditWrapper.instance.logPageAccess(1);
                        }),
                        buildNavItem(2, 'Announcements', Icons.warning_outlined,
                            isSelected: _selectedIndex == 2, onTap: () {
                          setState(() => _selectedIndex = 2);
                          AuditWrapper.instance.logPageAccess(2);
                        }),
                        buildNavItem(3, 'Users', Icons.people_outlined,
                            isSelected: _selectedIndex == 3, onTap: () {
                          setState(() => _selectedIndex = 3);
                          AuditWrapper.instance.logPageAccess(3);
                        }),
                        buildNavItem(4, 'User Logs', Icons.people_outlined,
                            isSelected: _selectedIndex == 4, onTap: () {
                          setState(() => _selectedIndex = 4);
                          AuditWrapper.instance.logPageAccess(4);
                        }),
                        buildNavItem(5, 'Reports', Icons.description_outlined,
                            isSelected: _selectedIndex == 5, onTap: () {
                          setState(() => _selectedIndex = 5);
                          AuditWrapper.instance.logPageAccess(5);
                        }),
                        buildNavItem(6, 'Chat', Icons.chat_outlined,
                            isSelected: _selectedIndex == 6, onTap: () {
                          setState(() => _selectedIndex = 6);
                          AuditWrapper.instance.logPageAccess(6);
                        }),
                        buildNavItem(7, 'Audit Logs', Icons.history_outlined,
                            isSelected: _selectedIndex == 7, onTap: () {
                          setState(() => _selectedIndex = 7);
                          AuditWrapper.instance.logPageAccess(7);
                        }),
                        buildNavItem(8, 'Settings', Icons.settings_outlined,
                            isSelected: _selectedIndex == 8, onTap: () {
                          setState(() => _selectedIndex = 8);
                          AuditWrapper.instance.logPageAccess(8);
                        }),
                        buildNavItem(
                            9, 'Security Guards', Icons.security_outlined,
                            isSelected: _selectedIndex == 9, onTap: () {
                          setState(() => _selectedIndex = 9);
                          AuditWrapper.instance.logPageAccess(9);
                        }),
                      ],
                    ),
                  ),
                  // Page Content
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.blue.shade50, Colors.white],
                        ),
                      ),
                      child: _pages[_selectedIndex],
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
}

class NotificationPanel extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onMarkAllRead;
  final VoidCallback onNavigateToReports;
  final VoidCallback onNavigateToAlcoholDetection;

  const NotificationPanel({
    super.key,
    required this.onClose,
    required this.onMarkAllRead,
    required this.onNavigateToReports,
    required this.onNavigateToAlcoholDetection,
  });

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  bool _isExpanded = false;
  int _displayLimit = 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: _isExpanded ? 600 : 500),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          buildNotificationHeader(
            onClose: widget.onClose,
            onMarkAllRead: widget.onMarkAllRead,
          ),
          Divider(height: 1, color: Colors.grey.shade200),

          // Notification list - using FutureBuilder to combine both notification types
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getCombinedNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      'Error loading notifications: ${snapshot.error}',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                );
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Container(
                constraints: BoxConstraints(
                  maxHeight: _isExpanded ? 500 : 350,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final notificationType = notification['type'];

                    if (notificationType == 'breathalyzer') {
                      return _buildBreatheanalyzerNotificationItem(
                          notification);
                    } else {
                      return _buildRegularNotificationItem(notification);
                    }
                  },
                ),
              );
            },
          ),

          // Footer
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Center(
              child: buildNotificationActionButton(
                isExpanded: _isExpanded,
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                    _displayLimit = _isExpanded ? 20 : 5;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getCombinedNotifications() async {
    final List<Map<String, dynamic>> combinedNotifications = [];

    try {
      // Get regular admin notifications
      final adminSnapshot = await FirebaseFirestore.instance
          .collection('notification_to_admin')
          .orderBy('createdAt', descending: true)
          .limit(_isExpanded ? 20 : _displayLimit)
          .get();

      // Convert and add admin notifications
      for (var doc in adminSnapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        data['type'] = 'admin';
        combinedNotifications.add(data);
      }

      // Get breathalyzer notifications
      final breathalyzerSnapshot = await FirebaseFirestore.instance
          .collection('notification_from_breatheanalyzer')
          .orderBy('timestamp', descending: true)
          .limit(_isExpanded ? 20 : _displayLimit)
          .get();

      // Convert and add breathalyzer notifications
      for (var doc in breathalyzerSnapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        data['type'] = 'breathalyzer';
        combinedNotifications.add(data);
      }

      // Sort all notifications by timestamp
      combinedNotifications.sort((a, b) {
        final aTime = a['type'] == 'admin'
            ? (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0
            : (a['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;

        final bTime = b['type'] == 'admin'
            ? (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0
            : (b['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;

        return bTime.compareTo(aTime); // Descending order
      });

      // Limit the final list
      if (combinedNotifications.length > (_isExpanded ? 20 : _displayLimit)) {
        return combinedNotifications.sublist(
            0, _isExpanded ? 20 : _displayLimit);
      }

      return combinedNotifications;
    } catch (e) {
      print('Error combining notifications: $e');
      return [];
    }
  }

  Widget _buildBreatheanalyzerNotificationItem(
      Map<String, dynamic> notification) {
    final notificationId = notification['id'];
    final isRead = notification['status'] != 'unread';
    final timestamp = notification['timestamp'] as Timestamp?;
    final formattedTime = timestamp != null
        ? getFormattedTimeAgo(timestamp.toDate())
        : 'Unknown time';

    // Extract info from breathalyzer notification
    final bac = notification['bac'] ?? '';
    final deviceId = notification['deviceId'] ?? '';
    final location = notification['location'] ?? '';
    final message = notification['message'] ?? 'Alcohol Detected';

    // Create message for display
    final displayMessage = 'Alcohol detected (${bac}) at $location';

    // Notification tap handler
    void handleNotificationTap() {
      // Mark as read
      if (!isRead) {
        FirebaseFirestore.instance
            .collection('notification_from_breatheanalyzer')
            .doc(notificationId)
            .update({'status': 'read'}).catchError((error) =>
                print('Error marking breathalyzer notification: $error'));
      }

      // Close panel and navigate to alcohol detection page
      widget.onClose();
      widget.onNavigateToAlcoholDetection();
    }

    return buildModernNotificationItem(
      message: displayMessage,
      time: formattedTime,
      isRead: isRead,
      notificationId: notificationId,
      location: location,
      incidentType: 'alcohol_detection',
      userImageUrl: '',
      onTap: handleNotificationTap,
    );
  }

  Widget _buildRegularNotificationItem(Map<String, dynamic> notification) {
    final notificationId = notification['id'];
    final isRead = notification['isRead'] ?? false;
    final timestamp = notification['createdAt'] as Timestamp?;
    final formattedTime = timestamp != null
        ? getFormattedTimeAgo(timestamp.toDate())
        : 'Unknown time';

    // Extract info from notification
    final reportId = notification['reportId'] ?? '';
    final userImageUrl = notification['userProfileImage'] ?? '';
    final userId = notification['userId'] ?? '';
    final incidentType = notification['incidentType'] ?? '';
    final userName = notification['userName'] ?? 'A user';
    final location = notification['location'] ?? '';

    // Format the message in the style shown in the image
    String displayMessage;
    if (incidentType.isNotEmpty) {
      displayMessage = '$userName has submitted a new $incidentType report.';
    } else {
      displayMessage = notification['message'] ?? 'New notification';
    }

    // Notification tap handler
    void handleNotificationTap() {
      // Mark as read
      if (!isRead) {
        FirebaseFirestore.instance
            .collection('notification_to_admin')
            .doc(notificationId)
            .update({'isRead': true}).catchError(
                (error) => print('Error marking notification: $error'));
      }

      // Close panel and navigate
      widget.onClose();
      widget.onNavigateToReports();
    }

    // If we need to fetch user image, use FutureBuilder
    if (userImageUrl.isEmpty && userId.isNotEmpty) {
      return FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, userSnapshot) {
          String imageUrl = '';

          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            imageUrl =
                userData['profileImageUrl'] ?? userData['imageUrl'] ?? '';
          }

          return buildModernNotificationItem(
            message: displayMessage,
            time: formattedTime,
            isRead: isRead,
            notificationId: notificationId,
            location: location,
            incidentType: incidentType,
            userImageUrl: imageUrl,
            onTap: handleNotificationTap,
          );
        },
      );
    }

    return buildModernNotificationItem(
      message: displayMessage,
      time: formattedTime,
      isRead: isRead,
      notificationId: notificationId,
      location: location,
      incidentType: incidentType,
      userImageUrl: userImageUrl,
      onTap: handleNotificationTap,
    );
  }
}
