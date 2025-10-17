import 'package:flutter/material.dart';
import 'auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String? message; // Add this parameter to receive messages

  const EmailVerificationScreen({Key? key, this.message}) : super(key: key);

  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isLoading = false;
  bool isVerified = false;

  @override
  void initState() {
    super.initState();
    // Show welcome message if coming from signup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.message!),
            duration: Duration(seconds: 4),
          ),
        );
      }
    });
  }

  Future<void> _checkVerification() async {
    setState(() => isLoading = true);
    isVerified = await AuthService.checkEmailVerified();
    setState(() => isLoading = false);

    if (isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email verified successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _resendVerification() async {
    setState(() => isLoading = true);
    try {
      await AuthService.resendVerificationEmail();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification email resent!'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend verification email'),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verify Email')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Please verify your email address',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              Text(
                'We\'ve sent a verification email to your email address. '
                'Please check your inbox and click the verification link.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _checkVerification,
                    child: Text('I\'ve verified my email'),
                  ),
              TextButton(
                onPressed: _resendVerification,
                child: Text('Resend verification email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
