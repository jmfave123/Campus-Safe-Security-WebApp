// ignore_for_file: avoid_types_as_parameter_names, unnecessary_brace_in_string_interps

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:campus_safe_app_admin_capstone/services/backup_service.dart';
import 'package:campus_safe_app_admin_capstone/services/data_analytics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// USTP brand palette
const Color kPrimaryColor = Color(0xFF1A1851); // was Colors.blue
const Color kAccentColor =
    Color(0xFFFBB215); // was Colors.amber / orange accents

BoxDecoration boxDecoration(Color color, Color shadowColor, double spreadRadius,
    double blurRadius, Offset offset) {
  return BoxDecoration(
    color: color,
    boxShadow: [
      BoxShadow(
        color: shadowColor,
        spreadRadius: spreadRadius,
        blurRadius: blurRadius,
        offset: offset,
      ),
    ],
  );
}

BoxDecoration boxDecoration2(Color color, double radius, Color shadowColor,
    double opacity, double spreadRadius, double blurRadius, Offset offset) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: shadowColor.withOpacity(opacity),
        spreadRadius: spreadRadius,
        blurRadius: blurRadius,
        offset: offset,
      ),
    ],
  );
}

Row rowWidget(double padding, Color color, double opacity, double borderRadius,
    IconData icon, double size, String text, FontWeight fontWeight) {
  return Row(
    children: [
      Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: color.withOpacity(opacity),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(icon, size: size, color: color),
      ),
      SizedBox(width: size),
      Text(text,
          style:
              TextStyle(color: color, fontSize: size, fontWeight: fontWeight)),
    ],
  );
}

Widget profileMenuWidget({
  required double borderRadius,
  required Color shadowColor,
  required double shadowOpacity,
  required double spreadRadius,
  required double blurRadius,
  required Offset menuOffset,
  required double avatarRadius,
  required Color avatarBackgroundColor,
  required List<Color> gradientColors,
  required IconData avatarIcon,
  required Color avatarIconColor,
  required List<PopupMenuItem> menuItems,
  Function()? onSelected,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: shadowColor.withOpacity(shadowOpacity),
          spreadRadius: spreadRadius,
          blurRadius: blurRadius,
        ),
      ],
    ),
    child: PopupMenuButton(
      offset: menuOffset,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      icon: CircleAvatar(
        radius: avatarRadius,
        backgroundColor: avatarBackgroundColor,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(avatarIcon, color: avatarIconColor),
        ),
      ),
      itemBuilder: (context) => menuItems,
      onSelected: onSelected != null ? (value) => onSelected() : null,
    ),
  );
}

Widget buildNavItem(int index, String title, IconData icon,
    {required bool isSelected, required Function() onTap}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          // color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          color:
              isSelected ? kPrimaryColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            // color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
            color: isSelected
                ? kPrimaryColor.withOpacity(0.22)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                // color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                color: isSelected
                    ? kPrimaryColor.withOpacity(0.18)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                // color: isSelected ? Colors.blue : Colors.grey[700],
                color: isSelected ? kPrimaryColor : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  // color: isSelected ? Colors.blue : Colors.grey[700],
                  color: isSelected ? kPrimaryColor : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

//NOTIFICATIONS

Widget buildNotificationItem({
  required String message,
  required String time,
  required bool isRead,
  required String notificationId,
  required IconData statusIcon,
  required LinearGradient statusGradient,
  required Function() onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // gradient: isRead ? null : LinearGradient(colors: [Colors.blue.shade50.withOpacity(0.4), Colors.white]),
        gradient: isRead
            ? null
            : LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [kPrimaryColor.withOpacity(0.06), Colors.white],
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: statusGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusIcon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (!isRead)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                // gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade700]),
                gradient: LinearGradient(
                  colors: [
                    kPrimaryColor.withOpacity(0.6),
                    kPrimaryColor.withOpacity(0.95)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    ),
  );
}

// Modern notification item with clean design
Widget buildModernNotificationItem({
  required String message,
  required String time,
  required bool isRead,
  required String notificationId,
  required String location,
  required String incidentType,
  required String userImageUrl,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.white,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile image or incident icon
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: userImageUrl.isNotEmpty
                  ? Image.network(
                      userImageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return buildIncidentTypeIcon(incidentType);
                      },
                    )
                  : buildIncidentTypeIcon(incidentType),
            ),
            const SizedBox(width: 12),
            // Notification content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      color: Colors.black.withOpacity(0.8),
                    ),
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Time information
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Helper to build incident type icons with appropriate colors
Widget buildIncidentTypeIcon(String incidentType) {
  Color backgroundColor;
  IconData iconData;

  switch (incidentType.toLowerCase()) {
    case 'harassment':
      backgroundColor = Colors.purple;
      iconData = Icons.person_off;
      break;
    case 'fighting':
      backgroundColor = Colors.orange;
      iconData = Icons.sports_kabaddi;
      break;
    case 'vandalism':
      backgroundColor = Colors.red;
      iconData = Icons.broken_image;
      break;
    case 'theft':
      backgroundColor = Colors.red.shade700;
      iconData = Icons.money_off;
      break;
    case 'suspicious activity':
      backgroundColor = Colors.amber;
      iconData = Icons.visibility;
      break;
    default:
      // backgroundColor = Colors.blue;
      backgroundColor = kPrimaryColor;
      iconData = Icons.report_problem;
  }

  return Container(
    width: 40,
    height: 40,
    color: backgroundColor,
    alignment: Alignment.center,
    child: Icon(
      iconData,
      color: Colors.white,
      size: 20,
    ),
  );
}

// Notification header with bell icon and title
Widget buildNotificationHeader({
  required VoidCallback onClose,
  required VoidCallback onMarkAllRead,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                // color: Colors.blue,
                color: kPrimaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        Row(
          children: [
            TextButton(
              onPressed: onMarkAllRead,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
                // foregroundColor: Colors.blue,
                foregroundColor: kPrimaryColor,
              ),
              child: const Text('Mark all as read'),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onClose,
              visualDensity: VisualDensity.compact,
              tooltip: 'Close',
            ),
          ],
        ),
      ],
    ),
  );
}

// Notification action button (See All/See Less)
Widget buildNotificationActionButton({
  required bool isExpanded,
  required VoidCallback onPressed,
}) {
  return TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      foregroundColor: Colors.white,
      // backgroundColor: Colors.blue,
      backgroundColor: kPrimaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    child: Text(isExpanded ? 'See Less' : 'See All Notifications'),
  );
}

// Helper for formatting time in a readable format
String getFormattedTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  } else if (difference.inDays < 30) {
    return '${difference.inDays}d ago';
  } else {
    return DateFormat('MMM d').format(dateTime);
  }
}

// Success Dialog Widget
Widget buildSuccessDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String buttonText,
  required VoidCallback onButtonPressed,
  IconData icon = Icons.check_circle_outline,
  List<Color>? gradientColors,
  int delayMilliseconds = 300,
}) {
  if (gradientColors == null || gradientColors.isEmpty) {
    // gradientColors = [Colors.blue.shade400, Colors.blue.shade700];
    gradientColors = [kPrimaryColor.withOpacity(0.6), kPrimaryColor];
  }

  Future.delayed(Duration(milliseconds: delayMilliseconds), () {
    // Check if the context is still mounted before showing the dialog
    if (context.mounted) {
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors!,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    // color: Colors.blue.shade200.withOpacity(0.5),
                    color: kPrimaryColor.withOpacity(0.18),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 60,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: onButtonPressed,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 10),
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        color: gradientColors.last,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  });

  // Return an empty container since the actual dialog is shown via showDialog
  return Container();
}

//REPORTS SCREEN WIDGETS

Widget buildReportStatCard(
    String title, IconData icon, Color color, String count) {
  return Expanded(
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildStatusChip(String status) {
  Color chipColor;
  IconData statusIcon;

  switch (status.toLowerCase()) {
    case 'resolved':
      chipColor = Colors.green;
      statusIcon = Icons.check_circle;
      break;
    case 'pending':
      chipColor = Colors.orange;
      statusIcon = Icons.pending;
      break;
    case 'in progress':
      // chipColor = Colors.blue;
      chipColor = kPrimaryColor;
      statusIcon = Icons.sync;
      break;
    case 'false information':
      chipColor = Colors.red.shade700;
      statusIcon = Icons.report_problem;
      break;
    default:
      chipColor = Colors.grey;
      statusIcon = Icons.help_outline;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: chipColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: chipColor.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          statusIcon,
          size: 12,
          color: chipColor,
        ),
        const SizedBox(width: 4),
        Text(
          status.toUpperCase(),
          style: TextStyle(
            color: chipColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

Widget buildInfoTile({
  required IconData icon,
  required String label,
  String? value,
  Widget? customWidget,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            // previous: color: Colors.blue.withOpacity(0.1),
            color: kPrimaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            // previous: color: Colors.blue,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              customWidget ??
                  Text(
                    value ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildDateFilterButton({
  required String selectedFilter,
  required Function(String) onFilterSelected,
  required Function() onCustomDateSelected,
  List<Map<String, dynamic>>? customFilterOptions,
}) {
  return Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: kPrimaryColor.withOpacity(0.2),
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
        onFilterSelected(value);
        if (value == 'Custom') {
          onCustomDateSelected();
        }
      },
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      itemBuilder: (BuildContext context) {
        final defaultOptions = [
          {'value': 'Today', 'icon': Icons.today},
          {'value': 'Yesterday', 'icon': Icons.history},
          {'value': 'Last Week', 'icon': Icons.date_range},
          {'value': 'Last Month', 'icon': Icons.calendar_month},
          {'value': 'All', 'icon': Icons.all_inclusive},
          {'value': 'Custom', 'icon': Icons.calendar_today},
        ];

        final options = customFilterOptions ?? defaultOptions;

        return options.map((option) {
          final isSelected = selectedFilter == option['value'];
          return PopupMenuItem<String>(
            value: option['value'] as String,
            child: Row(
              children: [
                Icon(
                  option['icon'] as IconData,
                  size: 20,
                  color: isSelected ? kPrimaryColor : Colors.grey.shade700,
                ),
                const SizedBox(width: 12),
                Text(
                  option['value'] as String,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? kPrimaryColor : Colors.black,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  // const Icon(Icons.check, size: 16, color: Colors.blue),
                  const Icon(Icons.check, size: 16, color: Color(0xFF1A1851)),
                ],
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.9)],
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
              'Filter: $selectedFilter',
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

//DATA ANALYTICS
Widget buildReportsAnalysisWidget({
  required BuildContext context,
  required String title,
  required IconData icon,
  required String buttonText,
  required String routeName,
  required String collectionName,
  required String orderByField,
  required Widget Function(List<QueryDocumentSnapshot>) buildChartFunction,
  VoidCallback? onButtonPressed,
  bool descending = false,
}) {
  return Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // color: Colors.blue.withOpacity(0.1),
                    color: kPrimaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    // color: Colors.blue,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextButton.icon(
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(buttonText),
                style: TextButton.styleFrom(
                  // previous: foregroundColor: Colors.blue,
                  foregroundColor: kPrimaryColor,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    // previous: side: BorderSide(color: Colors.blue.shade100),
                    side: BorderSide(color: kPrimaryColor.withOpacity(0.15)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                onPressed: onButtonPressed ??
                    () {
                      // Navigate to full reports page
                      Navigator.of(context).pushNamed(routeName);
                    },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(collectionName)
                .orderBy(orderByField, descending: descending)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading data',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final documents = snapshot.data?.docs ?? [];

              if (documents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No data available',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Process data for chart using the provided function
              return buildChartFunction(documents);
            },
          ),
        ),
      ],
    ),
  );
}

Widget buildStatCard(String title, String value, IconData icon, Color color) {
  return Expanded(
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Instance of the analytics service
final DataAnalyticsService _analyticsService = DataAnalyticsService();

Widget buildMonthlyReportChart(
  List<QueryDocumentSnapshot> documents, {
  required String timestampField,
  required String chartTitle,
  required String yAxisTitle,
  required Color chartColor,
  required String insightTitle,
  String? itemLabel,
  bool includeAllMonths = false,
  bool countUniqueIds = false,
}) {
  final now = DateTime.now();
  final List<String> monthAbbr = _analyticsService.getMonthAbbr();
  final Map<String, int> monthlyReportCounts =
      _analyticsService.getMonthlyCounts(
    documents,
    timestampField,
    includeAllMonths: includeAllMonths,
    countUniqueIds: countUniqueIds,
  );
  final List<String> monthKeys = [
    for (int i = 0; i < 12; i++)
      DateFormat('MMM yyyy').format(DateTime(now.year, i + 1, 1))
  ];
  final List<double> values =
      _analyticsService.getMonthlyValues(monthlyReportCounts, monthKeys);
  final maxCount =
      values.fold(0.0, (prev, count) => count > prev ? count : prev);
  final interval =
      _analyticsService.calculateAppropriateInterval(maxCount.toInt());
  final label = itemLabel ?? 'report';

  // If there is no meaningful data (empty or all zero), show a friendly placeholder
  final bool allZero = values.isEmpty || values.every((v) => v == 0);
  if (allZero) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No data available for the selected period',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try refreshing or adjust filters.',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.analytics_outlined, color: chartColor, size: 20),
          const SizedBox(width: 8),
          Text(
            chartTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Monthly trend of ${label}s for ${now.year} (${documents.length} total)',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(
            right: 16.0,
            top: 16.0,
            bottom: 24.0,
            left: 8.0,
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: interval,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(
                    'Months',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < monthAbbr.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            monthAbbr[index],
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    yAxisTitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) {
                        return const SizedBox.shrink();
                      }
                      if (value == value.toInt().toDouble()) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  left: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              minX: 0,
              maxX: 11,
              minY: 0,
              maxY: (maxCount + interval) < maxCount * 1.2
                  ? maxCount * 1.2
                  : (maxCount + interval).toDouble(),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey.shade800,
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.all(8),
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      if (index < 0 ||
                          index >= monthKeys.length ||
                          index >= values.length) {
                        return null;
                      }
                      final monthYear = monthKeys[index];
                      final count = values[index].toInt();
                      return LineTooltipItem(
                        '$monthYear\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: '$count $label${count == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                          )
                        ],
                      );
                    }).toList();
                  },
                ),
                touchCallback:
                    (FlTouchEvent event, LineTouchResponse? touchResponse) {},
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: values.isNotEmpty
                        ? values.reduce((a, b) => a + b) / values.length
                        : 0,
                    color: Colors.grey.shade400,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(right: 5, bottom: 5),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                      labelResolver: (line) =>
                          'Avg: ${line.y.toStringAsFixed(1)}',
                    ),
                  ),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(values.length > 12 ? 12 : values.length,
                      (index) => FlSpot(index.toDouble(), values[index])),
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: [
                      chartColor.withOpacity(0.7),
                      chartColor,
                    ],
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      if (values.isNotEmpty) {
                        final double average =
                            values.reduce((a, b) => a + b) / values.length;
                        final double maxVal =
                            values.reduce((a, b) => a > b ? a : b);
                        final double minVal =
                            values.reduce((a, b) => a < b ? a : b);
                        if (spot.y == maxVal && maxVal > 0) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: Colors.redAccent,
                            strokeWidth: 3,
                            strokeColor: Colors.white,
                          );
                        } else if (spot.y == minVal && minVal >= 0) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: Colors.greenAccent,
                            strokeWidth: 3,
                            strokeColor: Colors.white,
                          );
                        } else if (spot.y == average && values.length > 1) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: Colors.blueGrey,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        }
                      }
                      return FlDotCirclePainter(
                        radius: 4,
                        color: chartColor,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        chartColor.withOpacity(0.3),
                        chartColor.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: chartColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: chartColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: chartColor.withOpacity(0.8)),
                const SizedBox(width: 8),
                Text(
                  insightTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: chartColor.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: _analyticsService.getAIInsights(
                values: values,
                months: monthAbbr,
                itemLabel: label,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              chartColor.withOpacity(0.8)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Generating AI insight...',
                        style: TextStyle(
                          fontSize: 12,
                          color: chartColor.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Text(
                    'AI insight unavailable. Showing manual insight.\n${_analyticsService.getInsightsFromData(values, monthAbbr, itemLabel: label)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: chartColor.withOpacity(0.8),
                      height: 1.4,
                    ),
                  );
                } else if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.trim().isNotEmpty) {
                  return Text(
                    snapshot.data!,
                    style: TextStyle(
                      fontSize: 12,
                      color: chartColor.withOpacity(0.8),
                      height: 1.4,
                    ),
                  );
                } else {
                  return Text(
                    _analyticsService.getInsightsFromData(values, monthAbbr,
                        itemLabel: label),
                    style: TextStyle(
                      fontSize: 12,
                      color: chartColor.withOpacity(0.8),
                      height: 1.4,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    ],
  );
}

//reusable widget for throw_alerts.dart file

Widget buildStatCardAlerts(
    String title, Widget valueWidget, IconData icon, Color color) {
  return Container(
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
        valueWidget,
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
  );
}

Widget receiptInfoRow(IconData icon, String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: Colors.blueGrey),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Shows a format selection dialog for backup
Future<BackupFormat?> showFormatSelectionDialog(BuildContext context) async {
  return await showDialog<BackupFormat>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      backgroundColor: Colors.white,
      elevation: 8.0,
      title: const Row(
        children: [
          // previous: Icon(Icons.backup_table_rounded, color: Colors.blue.shade700),
          Icon(Icons.backup_table_rounded, color: kPrimaryColor),
          SizedBox(width: 12),
          Text(
            'Select Backup Format',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose the format for your data backup. Each format has its own advantages.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          buildFormatOption(
            context,
            icon: Icons.code,
            title: 'JSON',
            subtitle: 'Technical format for developers.',
            format: BackupFormat.json,
            color: Colors.orange,
          ),
          buildFormatOption(
            context,
            icon: Icons.table_chart,
            title: 'CSV',
            subtitle: 'Spreadsheet format (multiple files).',
            format: BackupFormat.csv,
            color: Colors.green,
          ),
          buildFormatOption(
            context,
            icon: Icons.description,
            title: 'Excel',
            subtitle: 'Excel workbook (single file).',
            format: BackupFormat.excel,
            color: Colors.blue,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      ],
    ),
  );
}

Widget buildFormatOption(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required BackupFormat format,
  required Color color,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: () => Navigator.of(context).pop(format),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      hoverColor: color.withOpacity(0.05),
    ),
  );
}

/// Builds a pie chart widget for user type distribution
Widget buildUserTypePieChart(Map<String, int> userTypeCounts) {
  final List<Color> colors = [
    kPrimaryColor,
    kAccentColor,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  final total = userTypeCounts.values.fold(0, (sum, count) => sum + count);

  if (total == 0) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'No users data available',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  final List<PieChartSectionData> sections = [];
  int colorIndex = 0;

  userTypeCounts.forEach((userType, count) {
    final percentage = (count / total * 100);
    sections.add(
      PieChartSectionData(
        color: colors[colorIndex % colors.length],
        value: count.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
    colorIndex++;
  });

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 0,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart,
                  color: kPrimaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'User Distribution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: userTypeCounts.entries.map((entry) {
                      final color = colors[
                          userTypeCounts.keys.toList().indexOf(entry.key) %
                              colors.length];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${entry.key}: ${entry.value}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Users: $total',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Builds an enhanced user type pie chart with date filtering
Widget buildFilterableUserTypePieChart({
  required Map<String, int> userTypeCounts,
  required String selectedFilter,
  required Function(String) onFilterChanged,
  required VoidCallback onCustomDatePressed,
}) {
  final List<Color> colors = [
    kPrimaryColor,
    kAccentColor,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  final total = userTypeCounts.values.fold(0, (sum, count) => sum + count);

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 0,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filter button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart,
                  color: kPrimaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'User Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ),
              // Filter button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: kPrimaryColor.withOpacity(0.3),
                  ),
                ),
                child: PopupMenuButton<String>(
                  onSelected: (String value) {
                    if (value == 'Custom') {
                      onCustomDatePressed();
                    } else {
                      onFilterChanged(value);
                    }
                  },
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  itemBuilder: (BuildContext context) {
                    final options = [
                      {'value': 'Today', 'icon': Icons.today},
                      {'value': 'Yesterday', 'icon': Icons.history},
                      {'value': 'Last Week', 'icon': Icons.date_range},
                      {'value': 'Last Month', 'icon': Icons.calendar_month},
                      {'value': 'All', 'icon': Icons.all_inclusive},
                      {'value': 'Custom', 'icon': Icons.calendar_today},
                    ];

                    return options.map((option) {
                      final isSelected = selectedFilter == option['value'];
                      return PopupMenuItem<String>(
                        value: option['value'] as String,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? kPrimaryColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                option['icon'] as IconData,
                                size: 18,
                                color: isSelected
                                    ? kPrimaryColor
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                option['value'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? kPrimaryColor
                                      : Colors.grey.shade600,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.filter_list,
                          size: 18,
                          color: kPrimaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          selectedFilter,
                          style: const TextStyle(
                            fontSize: 12,
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: kPrimaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart content
          if (total == 0)
            const Expanded(
              child: Center(
                child: Text(
                  'No users data available for selected period',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: userTypeCounts.entries.map((entry) {
                          final colorIndex =
                              userTypeCounts.keys.toList().indexOf(entry.key);
                          final percentage = (entry.value / total * 100);
                          return PieChartSectionData(
                            color: colors[colorIndex % colors.length],
                            value: entry.value.toDouble(),
                            title: '${percentage.toStringAsFixed(1)}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: userTypeCounts.entries.map((entry) {
                        final colorIndex =
                            userTypeCounts.keys.toList().indexOf(entry.key);
                        final color = colors[colorIndex % colors.length];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${entry.key}: ${entry.value}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),
          Text(
            'Total Users: $total',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Builds a pie chart widget for incident type distribution
Widget buildIncidentTypePieChart(Map<String, int> incidentTypeCounts) {
  final Map<String, Color> incidentColors = {
    'Drunk Person': Colors.purple,
    'Theft': Colors.red.shade700,
    'Vandalism': Colors.red,
    'Fighting': Colors.orange,
    'Suspicious Activity': Colors.amber,
    'Harassment': Colors.deepPurple,
    'Others': Colors.grey,
  };

  final total = incidentTypeCounts.values.fold(0, (sum, count) => sum + count);

  if (total == 0) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'No incident data available',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  final List<PieChartSectionData> sections = [];

  incidentTypeCounts.forEach((incidentType, count) {
    final percentage = (count / total * 100);
    final color = incidentColors[incidentType] ?? Colors.grey;
    sections.add(
      PieChartSectionData(
        color: color,
        value: count.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  });

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 0,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.report_problem,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Incident Types',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: incidentTypeCounts.entries.map((entry) {
                      final color = incidentColors[entry.key] ?? Colors.grey;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${entry.key}: ${entry.value}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Reports: $total',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Builds an enhanced incident type pie chart with date filtering
Widget buildFilterableIncidentTypePieChart({
  required Map<String, int> incidentTypeCounts,
  required String selectedFilter,
  required Function(String) onFilterChanged,
  required VoidCallback onCustomDatePressed,
}) {
  final Map<String, Color> incidentColors = {
    'Drunk Person': Colors.purple,
    'Theft': Colors.red.shade700,
    'Vandalism': Colors.red,
    'Fighting': Colors.orange,
    'Suspicious Activity': Colors.amber,
    'Harassment': Colors.deepPurple,
    'Others': Colors.grey,
  };

  final total = incidentTypeCounts.values.fold(0, (sum, count) => sum + count);

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 0,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filter dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.report_problem,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Incident Types',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              // Filter button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: kPrimaryColor.withOpacity(0.3),
                  ),
                ),
                child: PopupMenuButton<String>(
                  onSelected: (String value) {
                    if (value == 'Custom') {
                      onCustomDatePressed();
                    } else {
                      onFilterChanged(value);
                    }
                  },
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  itemBuilder: (BuildContext context) {
                    final options = [
                      {'value': 'Today', 'icon': Icons.today},
                      {'value': 'Yesterday', 'icon': Icons.history},
                      {'value': 'Last Week', 'icon': Icons.date_range},
                      {'value': 'Last Month', 'icon': Icons.calendar_month},
                      {'value': 'All', 'icon': Icons.all_inclusive},
                      {'value': 'Custom', 'icon': Icons.calendar_today},
                    ];

                    return options.map((option) {
                      final isSelected = selectedFilter == option['value'];
                      return PopupMenuItem<String>(
                        value: option['value'] as String,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? kPrimaryColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                option['icon'] as IconData,
                                size: 18,
                                color: isSelected
                                    ? kPrimaryColor
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                option['value'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? kPrimaryColor
                                      : Colors.grey.shade600,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.filter_list,
                          size: 18,
                          color: kPrimaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          selectedFilter,
                          style: const TextStyle(
                            fontSize: 12,
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: kPrimaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chart content
          if (total == 0)
            Expanded(
              child: Center(
                child: Text(
                  'No incident data available for $selectedFilter',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: incidentTypeCounts.entries.map((entry) {
                          final percentage = (entry.value / total * 100);
                          final color =
                              incidentColors[entry.key] ?? Colors.grey;
                          return PieChartSectionData(
                            color: color,
                            value: entry.value.toDouble(),
                            title: '${percentage.toStringAsFixed(1)}%',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: incidentTypeCounts.entries.map((entry) {
                        final color = incidentColors[entry.key] ?? Colors.grey;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${entry.key}: ${entry.value}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Total Reports: $total (${selectedFilter})',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Shows a compact custom date range picker dialog
Future<Map<String, DateTime?>?> showCustomDateRangePicker(
    BuildContext context) async {
  DateTime? startDate;
  DateTime? endDate;

  return await showDialog<Map<String, DateTime?>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.date_range,
                    color: kPrimaryColor,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Select Date Range',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Start Date
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: const Icon(Icons.event, color: Colors.grey),
                  title: Text(
                    startDate != null
                        ? 'Start: ${DateFormat('MMM dd, yyyy').format(startDate!)}'
                        : 'Select Start Date',
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: kPrimaryColor,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() {
                        startDate = date;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),

              // End Date
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: const Icon(Icons.event, color: Colors.grey),
                  title: Text(
                    endDate != null
                        ? 'End: ${DateFormat('MMM dd, yyyy').format(endDate!)}'
                        : 'Select End Date',
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: kPrimaryColor,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() {
                        endDate = date;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (startDate != null && endDate != null) {
                        Navigator.of(context).pop({
                          'startDate': startDate,
                          'endDate': endDate,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Apply'),
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
