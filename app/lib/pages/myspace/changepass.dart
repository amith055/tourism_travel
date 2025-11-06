import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool showCurrent = false;
  bool showNew = false;
  bool showConfirm = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final user = _auth.currentUser;
      final cred = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPasswordController.text.trim(),
      );

      // Reauthenticate the user
      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(newPasswordController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully!")),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = "Error changing password";
      if (e.code == 'wrong-password') {
        message = "Incorrect current password";
      } else if (e.code == 'weak-password') {
        message = "New password is too weak";
      } else if (e.code == 'requires-recent-login') {
        message = "Please re-login to change your password.";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.cyanAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white10,
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Change Password"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 10),
              const Text(
                "Update Your Password",
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Current Password
              TextFormField(
                controller: currentPasswordController,
                obscureText: !showCurrent,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  "Current Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      showCurrent ? Icons.visibility : Icons.visibility_off,
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                    onPressed: () => setState(() => showCurrent = !showCurrent),
                  ),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? "Enter your current password"
                            : null,
              ),
              const SizedBox(height: 20),

              // New Password
              TextFormField(
                controller: newPasswordController,
                obscureText: !showNew,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  "New Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      showNew ? Icons.visibility : Icons.visibility_off,
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                    onPressed: () => setState(() => showNew = !showNew),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Enter a new password";
                  if (value.length < 6)
                    return "Password must be at least 6 characters";
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Confirm Password
              TextFormField(
                controller: confirmPasswordController,
                obscureText: !showConfirm,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  "Confirm New Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      showConfirm ? Icons.visibility : Icons.visibility_off,
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                    onPressed: () => setState(() => showConfirm = !showConfirm),
                  ),
                ),
                validator: (value) {
                  if (value != newPasswordController.text)
                    return "Passwords do not match";
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Save Button
              isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  )
                  : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _changePassword,
                    child: const Text(
                      "Update Password",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
