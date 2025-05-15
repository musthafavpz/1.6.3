import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Privacy Policy',
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
            _buildHeader("Academy LMS Privacy Policy"),
            _buildParagraph(
              "Last Updated: June 15, 2023",
              isItalic: true,
            ),
            
            _buildSectionHeader("1. Introduction"),
            _buildParagraph(
              "Welcome to Academy LMS. We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you about how we look after your personal data when you visit our application and tell you about your privacy rights and how the law protects you.",
            ),
            
            _buildSectionHeader("2. Data We Collect"),
            _buildParagraph(
              "We may collect, use, store and transfer different kinds of personal data about you which we have grouped together as follows:",
            ),
            _buildBulletPoint("Identity Data: includes first name, last name, username or similar identifier."),
            _buildBulletPoint("Contact Data: includes email address and telephone numbers."),
            _buildBulletPoint("Technical Data: includes internet protocol (IP) address, your login data, browser type and version, time zone setting and location, browser plug-in types and versions, operating system and platform, and other technology on the devices you use to access this application."),
            _buildBulletPoint("Profile Data: includes your username and password, purchases or orders made by you, your interests, preferences, feedback and survey responses."),
            _buildBulletPoint("Usage Data: includes information about how you use our application and services."),
            
            _buildSectionHeader("3. How We Use Your Data"),
            _buildParagraph(
              "We will only use your personal data when the law allows us to. Most commonly, we will use your personal data in the following circumstances:",
            ),
            _buildBulletPoint("To register you as a new user."),
            _buildBulletPoint("To process and deliver your course purchases."),
            _buildBulletPoint("To manage our relationship with you."),
            _buildBulletPoint("To enable you to participate in interactive features of our service."),
            _buildBulletPoint("To administer and protect our business and this application."),
            _buildBulletPoint("To deliver relevant content and advertisements to you."),
            
            _buildSectionHeader("4. Data Security"),
            _buildParagraph(
              "We have put in place appropriate security measures to prevent your personal data from being accidentally lost, used or accessed in an unauthorized way, altered or disclosed. In addition, we limit access to your personal data to those employees, agents, contractors and other third parties who have a business need to know.",
            ),
            
            _buildSectionHeader("5. Data Retention"),
            _buildParagraph(
              "We will only retain your personal data for as long as necessary to fulfill the purposes we collected it for, including for the purposes of satisfying any legal, accounting, or reporting requirements.",
            ),
            
            _buildSectionHeader("6. Your Legal Rights"),
            _buildParagraph(
              "Under certain circumstances, you have rights under data protection laws in relation to your personal data, including the right to:",
            ),
            _buildBulletPoint("Request access to your personal data."),
            _buildBulletPoint("Request correction of your personal data."),
            _buildBulletPoint("Request erasure of your personal data."),
            _buildBulletPoint("Object to processing of your personal data."),
            _buildBulletPoint("Request restriction of processing your personal data."),
            _buildBulletPoint("Request transfer of your personal data."),
            _buildBulletPoint("Right to withdraw consent."),
            
            _buildSectionHeader("7. Children's Privacy"),
            _buildParagraph(
              "Our app is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and you are aware that your child has provided us with personal information, please contact us so that we can take necessary actions.",
            ),
            
            _buildSectionHeader("8. Changes to Privacy Policy"),
            _buildParagraph(
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "last updated" date at the top of this Privacy Policy.',
            ),
            
            _buildSectionHeader("9. Contact Us"),
            _buildParagraph(
              "If you have any questions about this Privacy Policy, please contact us at:",
            ),
            _buildParagraph(
              "Email: privacy@academylms.com\nPhone: +1-234-567-8900\nAddress: 123 Learning Street, Education City, 12345",
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF6366F1),
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, {bool isItalic = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          height: 1.5,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
          color: const Color(0xFF555555),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
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
} 