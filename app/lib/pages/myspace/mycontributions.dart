import 'package:app/pages/ApiFunctions/functions.dart';
import 'package:app/pages/components/add_place_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MyContributionPage extends StatefulWidget {
  @override
  _MyContributionPageState createState() => _MyContributionPageState();
  final dynamic email;
  const MyContributionPage({super.key, required this.email});
}

class _MyContributionPageState extends State<MyContributionPage> {
  @override
  void initState() {
    super.initState();
    fetchcount();
  }

  var count;
  var credits;
  Future<void> fetchcount() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final querySnapshot =
        await firestore
            .collection('users')
            .where('email', isEqualTo: widget.email)
            .get();
    try {
      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        setState(() {
          count = userDoc['count'];
          credits = userDoc['credits'];
        });
      }
    } catch (e) {
      showSnackBar(context, "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("My Contributions"),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.amberAccent),
                SizedBox(width: 5),
                Text(
                  credits != null ? "$credits" : "...",
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child:
            count == 0
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color.fromARGB(255, 91, 91, 91),
                              const Color.fromARGB(255, 150, 150, 150),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        AddPlaceForm(email: widget.email),
                              ),
                            );
                          },
                          icon: Icon(Icons.add),
                          color: Colors.white,
                          iconSize: 40,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "You have not made any contributions yet",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                )
                : Text("You have made $count contributions."),
      ),
    );
  }
}
