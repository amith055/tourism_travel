import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

String getCurrentMonth() {
  final now = DateTime.now();
  final monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return monthNames[now.month - 1];
}

String getCurrentSeason() {
  DateTime now = DateTime.now();
  int month = now.month;

  if (month >= 3 && month <= 6) {
    return 'Summer';
  } else if (month >= 7 && month <= 9) {
    return 'Monsoon';
  } else if (month >= 10 && month <= 11) {
    return 'Spring';
  } else {
    return 'Winter';
  }
}

Widget imageloader(imageurl) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
      imageurl!,
      width: 120,
      height: 180,
      fit: BoxFit.cover,
      cacheWidth: 240, // half of the logical pixel width (double of 120)
      cacheHeight: 360,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Shimmer.fromColors(
          baseColor: Colors.grey[800]!,
          highlightColor: Colors.grey[700]!,
          child: Container(width: 120, height: 180, color: Colors.grey[900]),
        );
      },
    ),
  );
}
