import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'About Us',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF6366F1)),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo and App version
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/light_logo.png',
                    height: 80,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'Version 1.3.0',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Our Mission
            _buildSection(
              title: 'OUR MISSION',
              content: 'Our mission at Elegance Pro is to make quality education accessible to everyone, everywhere. We believe in the transformative power of learning and strive to create an environment where knowledge can be shared freely and effectively.',
            ),
            
            // About Us
            _buildSection(
              title: 'ABOUT US',
              content: 'Elegance Pro was founded in 2018 with a vision to revolutionize online education. Our platform connects expert instructors with eager learners from around the globe, offering a wide range of courses across various disciplines.\n\nStarting with just 5 courses and a handful of students, we have grown to feature over 1,000 courses and a community of more than 500,000 learners. Our success is built on our commitment to quality content, engaging teaching methods, and a user-friendly platform that makes learning enjoyable and effective.',
            ),
            
            // Our Team
            _buildSection(
              title: 'OUR TEAM',
              content: 'Elegance Pro is powered by a diverse team of educators, technologists, and lifelong learners. Our team members bring a wealth of experience from various fields, united by a shared passion for education and innovation.',
              useList: false,
            ),
            
            // Team Grid
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
                children: [
                  _buildTeamMember(
                    name: 'Musthafa CMA, CSCA',
                    role: 'Founder & CEO',
                    photoUrl: 'assets/images/team/member1.jpg',
                  ),
                  _buildTeamMember(
                    name: 'Michael Chen',
                    role: 'CTO',
                    photoUrl: 'assets/images/team/member2.jpg',
                  ),
                  _buildTeamMember(
                    name: 'Jessica Williams',
                    role: 'Head of Content',
                    photoUrl: 'assets/images/team/member3.jpg',
                  ),
                  _buildTeamMember(
                    name: 'David Martinez',
                    role: 'Lead Developer',
                    photoUrl: 'assets/images/team/member4.jpg',
                  ),
                ],
              ),
            ),
            
            // Our Values
            _buildSection(
              title: 'OUR VALUES',
              useList: true,
              listItems: [
                'Excellence: We strive for excellence in all our content and services.',
                'Accessibility: We believe education should be accessible to everyone.',
                'Innovation: We continuously innovate to improve the learning experience.',
                'Integrity: We conduct our business with honesty and transparency.',
                'Community: We foster a supportive community of learners and educators.',
              ],
            ),
            
            // Contact Section
            _buildSection(
              title: 'GET IN TOUCH',
              content: 'Have questions or feedback? We\'d love to hear from you. Reach out to our team through any of the following channels:',
              useList: false,
            ),
            
            // Contact Info
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildContactItem(
                      icon: Icons.email_outlined,
                      text: 'info@elegancepro.com',
                      onTap: () async {
                        final Uri emailUri = Uri(
                          scheme: 'mailto',
                          path: 'info@elegancepro.com',
                        );
                        if (await canLaunch(emailUri.toString())) {
                          await launch(emailUri.toString());
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildContactItem(
                      icon: Icons.phone_outlined,
                      text: '+1-234-567-8900',
                      onTap: () async {
                        final Uri phoneUri = Uri(
                          scheme: 'tel',
                          path: '+12345678900',
                        );
                        if (await canLaunch(phoneUri.toString())) {
                          await launch(phoneUri.toString());
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildContactItem(
                      icon: Icons.location_on_outlined,
                      text: '123 Learning St, Education City, 12345',
                      onTap: () async {
                        final Uri mapsUri = Uri(
                          scheme: 'https',
                          host: 'maps.google.com',
                          queryParameters: {
                            'q': '123 Learning St, Education City',
                          },
                        );
                        if (await canLaunch(mapsUri.toString())) {
                          await launch(mapsUri.toString());
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildContactItem(
                      icon: Icons.web_outlined,
                      text: 'www.elegancepro.com',
                      onTap: () async {
                        final Uri webUri = Uri(
                          scheme: 'https',
                          host: 'www.elegancepro.com',
                        );
                        if (await canLaunch(webUri.toString())) {
                          await launch(webUri.toString());
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Social media
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Follow Us',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialButton(
                          icon: Icons.facebook_outlined,
                          color: const Color(0xFF1877F2),
                          onTap: () {},
                        ),
                        _buildSocialButton(
                          icon: Icons.messenger_outline,
                          color: const Color(0xFF0084FF),
                          onTap: () {},
                        ),
                        _buildSocialButton(
                          icon: Icons.camera_alt_outlined,
                          color: const Color(0xFFE1306C),
                          onTap: () {},
                        ),
                        _buildSocialButton(
                          icon: Icons.discord_outlined,
                          color: const Color(0xFF5865F2),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? content,
    bool useList = false,
    List<String>? listItems,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          if (content != null)
            Text(
              content,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                height: 1.5,
                color: const Color(0xFF555555),
              ),
            ),
          if (useList && listItems != null)
            ...listItems.map((item) => _buildBulletPoint(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                height: 1.5,
                color: const Color(0xFF555555),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF6366F1),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: const Color(0xFF555555),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMember({
    required String name,
    required String role,
    required String photoUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                color: Colors.grey.shade200,
                child: Center(
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  // If you have actual team member photos, use this instead:
                  // Image.asset(
                  //   photoUrl,
                  //   fit: BoxFit.cover,
                  //   width: double.infinity,
                  //   height: double.infinity,
                  //   errorBuilder: (context, error, stackTrace) {
                  //     return Icon(
                  //       Icons.person,
                  //       size: 48,
                  //       color: Colors.grey.shade400,
                  //     );
                  //   },
                  // ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  name,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 