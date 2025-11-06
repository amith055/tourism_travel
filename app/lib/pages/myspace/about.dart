import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("About LokVista"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo Section
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/logo.png', // your logo
                    height: 100,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "LokVista",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Discover the Hidden Culture of India",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              "About LokVista",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "LokVista is a tourism and cultural discovery platform designed to promote the unexplored and traditional sides of India. "
              "It connects tourists with local experiences, cultural events, and hidden natural destinations. "
              "Locals can submit new places or festivals, which are verified by administrators before being featured in the app.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Core Features",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            buildFeature(
              "📍 Map Integration",
              "Users can explore tourist and cultural places through an interactive map with live location support.",
            ),
            buildFeature(
              "⚡ Smart Location Auto-Fill",
              "The app automatically detects the town, city, district, and state when a user selects a location.",
            ),
            buildFeature(
              "🗳️ Community Submissions",
              "Local residents can add hidden spots and events, verified by admins for authenticity.",
            ),
            buildFeature(
              "🖼️ Multimedia Gallery",
              "Each place features multiple images stored securely in Firebase Storage.",
            ),
            buildFeature(
              "🕊️ Modern Black UI",
              "Designed with a clean, modern dark interface for better user comfort and focus.",
            ),
            const SizedBox(height: 20),

            const Text(
              "Mission",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "To bridge the gap between local culture and global tourism by using technology to highlight India’s lesser-known heritage and traditions.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Tech Stack",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            buildFeature(
              "💙 Flutter",
              "For building a beautiful cross-platform mobile experience.",
            ),
            buildFeature(
              "🔥 Firebase",
              "For authentication, data storage, and cloud services.",
            ),
            buildFeature(
              "🗺️ Google Cloud",
              "Used for maps, geolocation, and image hosting.",
            ),
            const SizedBox(height: 30),

            Center(
              child: Text(
                "© 2025 LokVista • Made with ❤️ in India",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildFeature(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$title\n",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
