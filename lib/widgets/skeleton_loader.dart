import 'package:flutter/material.dart';

/// A skeleton loading widget that can be used to show loading placeholders
class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? color;

  const SkeletonLoader({
    Key? key,
    this.width = double.infinity,
    this.height = 20.0,
    this.borderRadius = 4.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A skeleton card that mimics the stat card layout
class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          const SkeletonLoader(width: 40, height: 24),
          const SizedBox(height: 8),
          const SkeletonLoader(width: 100, height: 16),
        ],
      ),
    );
  }
}

/// A skeleton for the campus status card
class SkeletonCampusStatusCard extends StatelessWidget {
  const SkeletonCampusStatusCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                const SkeletonLoader(width: 24, height: 24, borderRadius: 12),
                const SizedBox(width: 12),
                const Expanded(
                  child: SkeletonLoader(height: 24, borderRadius: 4),
                ),
                const SizedBox(width: 12),
                SkeletonLoader(
                  width: 80,
                  height: 12,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(height: 16, borderRadius: 4),
                const SizedBox(height: 8),
                const SkeletonLoader(
                  width: 200,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const SkeletonLoader(
                  width: 150,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 12),
                const SkeletonLoader(height: 50, borderRadius: 8),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: SkeletonLoader(
                    width: 120,
                    height: 40,
                    borderRadius: 8,
                    color: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A skeleton for the chart section
class SkeletonChartSection extends StatelessWidget {
  const SkeletonChartSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(width: 150, height: 24, borderRadius: 4),
                  SizedBox(height: 4),
                  SkeletonLoader(width: 200, height: 16, borderRadius: 4),
                ],
              ),
              SkeletonLoader(
                width: 120,
                height: 40,
                borderRadius: 8,
                color: Colors.grey[100],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 300,
                  borderRadius: 8,
                  color: Colors.grey[100],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SkeletonLoader(width: 100, height: 16, borderRadius: 4),
              Row(
                children: List.generate(
                  4,
                  (index) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: SkeletonLoader(
                      width: 24,
                      height: 24,
                      borderRadius: 12,
                      color: Colors.grey[100],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
