import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  String _selectedIssueType = 'Technical Issue';
  final List<String> _issueTypes = [
    'Technical Issue', 
    'Billing Question', 
    'Course Content', 
    'Account Problem',
    'Other'
  ];
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isSubmitting = false;
        });
        
        // Show success message
        Fluttertoast.showToast(
          msg: "Your support request has been submitted. We'll get back to you soon.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        
        // Reset form
        _subjectController.clear();
        _messageController.clear();
        setState(() {
          _selectedIssueType = 'Technical Issue';
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Help & Support',
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
            // Header section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      size: 40,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "How can we help you?",
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Get in touch with our support team",
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Quick contact options
            Text(
              "CONTACT US",
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            
            // Contact cards
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.email_outlined,
                    title: "Email",
                    subtitle: "support@academylms.com",
                    onTap: () async {
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: 'support@academylms.com',
                        query: 'subject=Support Request&body=Hello, I need assistance with...',
                      );
                      
                      if (await canLaunch(emailUri.toString())) {
                        await launch(emailUri.toString());
                      } else {
                        Fluttertoast.showToast(
                          msg: "Couldn't launch email client",
                          toastLength: Toast.LENGTH_SHORT,
                        );
                      }
                    },
                    color: const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.phone_outlined,
                    title: "Phone",
                    subtitle: "+1-234-567-8900",
                    onTap: () async {
                      final Uri phoneUri = Uri(
                        scheme: 'tel',
                        path: '+12345678900',
                      );
                      
                      if (await canLaunch(phoneUri.toString())) {
                        await launch(phoneUri.toString());
                      } else {
                        Fluttertoast.showToast(
                          msg: "Couldn't launch phone app",
                          toastLength: Toast.LENGTH_SHORT,
                        );
                      }
                    },
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Submit a ticket form
            Text(
              "SUBMIT A SUPPORT TICKET",
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
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
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Issue type dropdown
                    Text(
                      "Issue Type",
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedIssueType,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: const Color(0xFF333333),
                          ),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedIssueType = newValue!;
                            });
                          },
                          items: _issueTypes.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Subject field
                    Text(
                      "Subject",
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        hintText: "Brief description of your issue",
                        hintStyle: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6366F1)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a subject';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Message field
                    Text(
                      "Message",
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Describe your issue in detail",
                        hintStyle: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6366F1)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a message';
                        } else if (value.trim().length < 10) {
                          return 'Message must be at least 10 characters';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "Submit Request",
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // FAQ suggestion
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Need quick answers?",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Check our Frequently Asked Questions section for immediate solutions to common issues.",
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            // Navigate to FAQ page
                            Fluttertoast.showToast(
                              msg: "FAQ page coming soon",
                              toastLength: Toast.LENGTH_SHORT,
                            );
                          },
                          child: Text(
                            "View FAQs →",
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Container(
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
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 