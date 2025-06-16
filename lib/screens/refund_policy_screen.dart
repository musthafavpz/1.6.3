import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Refund Policy',
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
            _buildHeader("Refund Policy"),
            _buildParagraph(
              "Last Updated: June 15, 2023",
              isItalic: true,
            ),
            
            _buildSectionHeader("1. Course Refund Policy"),
            _buildParagraph(
              "At Elegance Prep, we strive to ensure customer satisfaction with all of our educational content. However, we understand that there may be times when a refund is necessary. Please read our refund policy carefully to understand the circumstances under which we provide refunds.",
            ),
            
            _buildSectionHeader("2. Refund Eligibility"),
            _buildParagraph(
              "You may be eligible for a refund in the following circumstances:",
            ),
            _buildBulletPoint("If you request a refund within 7 days of purchase and have not completed more than 15% of the course."),
            _buildBulletPoint("If there are significant technical issues with the course that prevent you from accessing or completing it, and our support team cannot resolve these issues within a reasonable timeframe."),
            _buildBulletPoint("If the course content is substantially different from what was advertised or described."),
            
            _buildSectionHeader("3. Refund Process"),
            _buildParagraph(
              "To request a refund, please follow these steps:",
            ),
            _buildBulletPoint("Log in to your account and navigate to the Contact page."),
            _buildBulletPoint("Fill out the contact form with your refund request details."),
            _buildBulletPoint("Include the course name, purchase date, and reason for your refund request."),
            _buildBulletPoint("Submit your request. Our team will review it and respond within 5 business days."),
            
            _buildSectionHeader("4. Refund Processing Time"),
            _buildParagraph(
              "Once your refund request has been approved, please allow 7-14 business days for the refund to be processed and credited back to your original payment method. Processing times may vary depending on your payment provider.",
            ),
            
            _buildSectionHeader("5. Non-Refundable Items"),
            _buildParagraph(
              "The following are not eligible for refunds:",
            ),
            _buildBulletPoint("Courses that have been completed more than 15%."),
            _buildBulletPoint("Courses purchased more than 7 days ago."),
            _buildBulletPoint("Special promotional or discounted courses marked as 'non-refundable'."),
            _buildBulletPoint("Add-on services such as mentorship sessions, completion certificates, or assessment fees."),
            
            _buildSectionHeader("6. Exceptional Circumstances"),
            _buildParagraph(
              "We may consider refund requests outside of our standard policy in exceptional circumstances. Such requests will be reviewed on a case-by-case basis. Please contact our customer support team through the Contact page to discuss your situation.",
            ),
            
            _buildSectionHeader("7. Currency and Payment Method"),
            _buildParagraph(
              "Refunds will be issued in the same currency and to the same payment method used for the original purchase. If the original payment method is no longer available, we will work with you to find an alternative solution.",
            ),
            
            _buildSectionHeader("8. Cancellation of Courses by Elegance Prep"),
            _buildParagraph(
              "In the rare event that Elegance Prep cancels a course, all enrolled students will receive a full refund, regardless of how much of the course they have completed.",
            ),
            
            _buildSectionHeader("9. Policy Changes"),
            _buildParagraph(
              "Elegance Prep reserves the right to modify this refund policy at any time. Any changes will be effective immediately upon posting the updated policy on our website.",
            ),
            
            _buildSectionHeader("10. Contact Us"),
            _buildParagraph(
              "If you have any questions about our refund policy or need assistance with a refund request, please contact our support team at:",
            ),
            _buildParagraph(
              "Email: support@eleganceprep.com\nSupport Hours: Monday to Friday, 9:00 AM to 6:00 PM EST",
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