// ignore_for_file: avoid_types_as_parameter_names, unnecessary_brace_in_string_interps

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.blue : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
        gradient: isRead
            ? null
            : LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.blue.shade50.withOpacity(0.4), Colors.white],
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
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade700],
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
      backgroundColor = Colors.blue;
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
                color: Colors.blue,
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
                foregroundColor: Colors.blue,
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
      backgroundColor: Colors.blue,
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
    gradientColors = [Colors.blue.shade400, Colors.blue.shade700];
  }

  Future.delayed(Duration(milliseconds: delayMilliseconds), () {
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
                  color: Colors.blue.shade200.withOpacity(0.5),
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
                      color: gradientColors!.last,
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
      chipColor = Colors.blue;
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
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.blue,
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
                  color: isSelected ? Colors.blue : Colors.grey.shade700,
                ),
                const SizedBox(width: 12),
                Text(
                  option['value'] as String,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
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
        }).toList();
      },
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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: Colors.blue,
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
                  foregroundColor: Colors.blue,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.blue.shade100),
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

// Helper method to calculate appropriate interval for y-axis
double calculateAppropriateInterval(int maxValue) {
  if (maxValue <= 5) return 1;
  if (maxValue <= 10) return 2;
  if (maxValue <= 20) return 4;
  if (maxValue <= 50) return 10;
  if (maxValue <= 100) return 20;
  return (maxValue / 5).ceilToDouble();
}

// Helper method to generate insights from the data
String getInsightsFromData(List<double> values, List<String> months,
    {String itemLabel = 'report'}) {
  if (values.isEmpty) return 'No data available for analysis.';

  // Find highest and lowest months
  int highestMonth = 0;
  int lowestMonth = 0;
  double highestValue = values[0];
  double lowestValue = values[0];

  for (int i = 1; i < values.length; i++) {
    if (values[i] > highestValue) {
      highestValue = values[i];
      highestMonth = i;
    }
    if (values[i] < lowestValue) {
      lowestValue = values[i];
      lowestMonth = i;
    }
  }

  // Calculate trend (increasing, decreasing, stable)
  String trend = 'stable';
  if (values.length > 3) {
    double recentAvg = (values[values.length - 1] +
            values[values.length - 2] +
            values[values.length - 3]) /
        3;
    double earlierAvg = (values[0] + values[1] + values[2]) / 3;

    if (recentAvg > earlierAvg * 1.2) {
      trend = 'increasing';
    } else if (recentAvg < earlierAvg * 0.8) {
      trend = 'decreasing';
    }
  }

  // Generate insight text
  return 'The highest number of ${itemLabel}s (${highestValue.toInt()}) was in ${months[highestMonth]}, '
      'while the lowest (${lowestValue.toInt()}) was in ${months[lowestMonth]}. '
      'Overall, ${itemLabel} submissions show a $trend trend over the last year.';
}

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
  final Map<String, int> monthlyReportCounts = {};
  final Map<String, Set<String>> monthlyUniqueDocIds =
      {}; // Track unique document IDs per month
  final now = DateTime.now();

  // Define standard month order from January to December
  final List<String> monthAbbr = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC'
  ];
  List<String> monthKeys = [];

  // Initialize all months in the current year with zero counts
  for (int i = 0; i < 12; i++) {
    final month = DateTime(now.year, i + 1, 1); // January is 1, December is 12
    final monthKey = DateFormat('MMM yyyy').format(month);
    monthKeys.add(monthKey);
    monthlyReportCounts[monthKey] = 0;
  }

  // Count reports by month
  for (var doc in documents) {
    final data = doc.data() as Map<String, dynamic>;
    if (data.containsKey(timestampField)) {
      final dynamic timestampData = data[timestampField];
      // Handle different timestamp formats
      DateTime date;
      if (timestampData is Timestamp) {
        date = timestampData.toDate();
      } else if (timestampData is int) {
        // Handle cases where timestamp might be stored as milliseconds
        date = DateTime.fromMillisecondsSinceEpoch(timestampData);
      } else if (timestampData is String) {
        // Try to parse string format
        try {
          date = DateTime.parse(timestampData);
        } catch (e) {
          print(
              'Error parsing timestamp string: $e for doc ${doc.id}. Skipping.');
          continue;
        }
      } else {
        print('Unsupported timestamp format for doc ${doc.id}. Skipping.');
        continue;
      }

      print('Processing doc: ${doc.id}, date: ${date.toString()}');

      // Only consider reports from the current year or include all if specified
      if (date.year == now.year || includeAllMonths) {
        final monthKey =
            DateFormat('MMM yyyy').format(DateTime(date.year, date.month, 1));
        print(
            '  Adding to month: $monthKey (previous count: ${monthlyReportCounts[monthKey] ?? 0})');

        // Check if we need to add this month to our tracking
        if (!monthlyReportCounts.containsKey(monthKey) && includeAllMonths) {
          // Only add if we don't exceed 12 months total
          if (monthKeys.length < 12) {
            monthKeys.add(monthKey);
            monthlyReportCounts[monthKey] = 0;
            if (countUniqueIds) {
              monthlyUniqueDocIds[monthKey] = <String>{};
            }
          }
        }

        if (countUniqueIds) {
          // Only count each document once per month
          if (!monthlyUniqueDocIds.containsKey(monthKey)) {
            monthlyUniqueDocIds[monthKey] = <String>{};
          }

          if (!monthlyUniqueDocIds[monthKey]!.contains(doc.id)) {
            monthlyUniqueDocIds[monthKey]!.add(doc.id);
            monthlyReportCounts[monthKey] =
                (monthlyReportCounts[monthKey] ?? 0) + 1;
            print(
                '  Added unique doc ${doc.id} to $monthKey. Updated count: ${monthlyReportCounts[monthKey]}');
          } else {
            print('  Skipping duplicate doc ${doc.id} for $monthKey');
          }
        } else {
          // Standard counting (may count duplicates)
          monthlyReportCounts[monthKey] =
              (monthlyReportCounts[monthKey] ?? 0) + 1;
          print('  Updated count: ${monthlyReportCounts[monthKey]}');
        }
      } else {
        print('  Skipping doc due to year filter: ${date.year} != ${now.year}');
      }
    } else {
      // If document doesn't contain the timestamp field, print for debugging
      print(
          'Document missing $timestampField field: ${doc.id}, available fields: ${data.keys.join(', ')}');
    }
  }

  print('Final monthly counts: $monthlyReportCounts');
  print('Month keys in order: $monthKeys');

  // Ensure monthKeys doesn't exceed 12 months
  if (monthKeys.length > 12) {
    print(
        'WARNING: More than 12 months detected, truncating to most recent 12 months');
    monthKeys = monthKeys.sublist(monthKeys.length - 12);
  }

  // Get the values in standard month order (Jan to Dec)
  final List<double> values = [];
  for (int i = 0; i < monthKeys.length; i++) {
    values.add(monthlyReportCounts[monthKeys[i]]?.toDouble() ?? 0);
  }

  // Ensure we have exactly 12 or fewer values
  if (values.length > 12) {
    print('WARNING: Truncating values to 12 elements');
    values.removeRange(12, values.length);
  }

  // Get the maximum count for y-axis scaling
  final maxCount =
      values.fold(0.0, (prev, count) => count > prev ? count : prev);

  // Calculate appropriate interval for grid lines based on maximum value
  final interval = calculateAppropriateInterval(maxCount.toInt());

  // Default item label if not provided
  final label = itemLabel ?? 'report';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Chart title with count summary
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

      // Chart description
      Text(
        'Monthly trend of ${label}s for ${now.year} (${documents.length} total)',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      const SizedBox(height: 16),

      // Main chart area
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
                      // Only show integer values
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

                      // Make sure index is in valid range
                      if (index < 0 ||
                          index >= monthKeys.length ||
                          index >= values.length) {
                        return null; // Skip this spot if index is out of range
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
                  spots: List.generate(
                      values.length > 12
                          ? 12
                          : values.length, // Limit to 12 max points
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

      // Chart information card
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
            Text(
              getInsightsFromData(values, monthAbbr, itemLabel: label),
              style: TextStyle(
                fontSize: 12,
                color: chartColor.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
