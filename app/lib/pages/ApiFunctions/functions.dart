import 'package:cloud_firestore/cloud_firestore.dart';
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
      cacheWidth: 240,
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

Future<void> updateContributorStatus(context, String email) async {
  try {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final QuerySnapshot userSnapshot = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      final String docId = userSnapshot.docs.first.id;
      await firestore.collection('users').doc(docId).update({
        'is_contributor': true,
        'credits': 0,
        'count': 0,
      });
      showSnackBar(context, "You are now a contributor!");
    } else {
      showSnackBar(context, "Error");
    }
  } catch (e) {
    showSnackBar(context, "An error occurred: $e");
  }
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.black)),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
