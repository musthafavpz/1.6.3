import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../providers/my_courses.dart';
import '../widgets/appbar_one.dart';

class CertificatesScreen extends StatefulWidget {
  static const routeName = '/certificates';
  
  const CertificatesScreen({Key? key}) : super(key: key);

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _fetchCertificates();
  }
  
  Future<void> _fetchCertificates() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Provider.of<MyCourses>(context, listen: false).fetchMyCourses();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load certificates: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBarOne(
        title: 'My Certificates',
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kDefaultColor),
            )
          : Consumer<MyCourses>(
              builder: (ctx, myCourses, _) {
                final completedCourses = myCourses.items
                    .where((course) => course.courseCompletion != null && course.courseCompletion! >= 100)
                    .toList();
                
                final inProgressCourses = myCourses.items
                    .where((course) => course.courseCompletion == null || course.courseCompletion! < 100)
                    .toList();
                
                return AnimationLimiter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header section
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF6366F1),
                                Color(0xFF8B5CF6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.school_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Your Achievements',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Download and share your certificates',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStat(
                                    count: completedCourses.length.toString(),
                                    label: 'Earned',
                                    icon: Icons.verified_rounded,
                                  ),
                                  _buildStat(
                                    count: inProgressCourses.length.toString(),
                                    label: 'In Progress',
                                    icon: Icons.pending_actions_rounded,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Certificates list
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: const Text(
                          'All Certificates',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      
                      Expanded(
                        child: myCourses.items.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.school_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No courses found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Enroll in courses to earn certificates',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: myCourses.items.length,
                                itemBuilder: (context, index) {
                                  return AnimationConfiguration.staggeredList(
                                    position: index,
                                    duration: const Duration(milliseconds: 375),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: _buildCertificateItem(myCourses.items[index]),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStat({
    required String count,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCertificateItem(dynamic course) {
    final bool isCompleted = course.courseCompletion != null && course.courseCompletion >= 100;
    final DateTime now = DateTime.now();
    final String dateEarned = isCompleted ? DateFormat('dd MMM yyyy').format(now) : '';
    final String certificateId = isCompleted ? 'CERT-${course.id}-${now.year}' : '';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Certificate icon or thumbnail
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      isCompleted ? Icons.verified_rounded : Icons.pending_actions_rounded,
                      color: isCompleted ? const Color(0xFF6366F1) : Colors.amber,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Certificate details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title ?? 'Course Title',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      isCompleted
                          ? Text(
                              'Earned on: $dateEarned',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'In Progress',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.amber[700],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: (course.courseCompletion ?? 0) / 100,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${course.courseCompletion ?? 0}% completed',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'ID: $certificateId',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          color: Colors.blue,
                          onTap: () {
                            _generateCertificatePdf(context, course, shouldShare: true);
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          icon: Icons.download_outlined,
                          color: const Color(0xFF6366F1),
                          onTap: () {
                            _generateCertificatePdf(context, course, shouldShare: false);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }
  
  Future<void> _generateCertificatePdf(BuildContext context, dynamic course, {bool shouldShare = false}) async {
    try {
      // Show loading indicator
      Fluttertoast.showToast(
        msg: shouldShare ? "Preparing certificate to share..." : "Generating certificate...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      
      // Get user details - with error handling
      String candidateName = 'Valued Student';
      try {
        final prefs = await SharedPreferences.getInstance();
        final userDataString = prefs.getString('user');
        if (userDataString != null && userDataString.isNotEmpty) {
          final userData = jsonDecode(userDataString);
          if (userData != null && userData['name'] != null) {
            candidateName = userData['name'];
          }
        }
      } catch (userError) {
        print("Error getting user data: $userError");
        // Continue with default name
      }

      // Get course details
      String courseName = course.title?.toString() ?? "Course";
      String courseDuration = "2hr"; // Default duration
      
      // Format today's date
      final DateTime now = DateTime.now();
      final String completionDate = DateFormat('MMMM dd, yyyy').format(now);
      final String shortDate = DateFormat('MMM dd, yyyy').format(now);
      
      // Generate a unique certificate ID
      final String certificateId = 'EDP${now.millisecondsSinceEpoch.toString().substring(5, 13)}';

      // Load logo image
      Uint8List? logoImageData;
      try {
        final ByteData logoData = await rootBundle.load('assets/images/light_logo.png');
        logoImageData = logoData.buffer.asUint8List();
      } catch (imageError) {
        print("Error loading logo: $imageError");
        // Continue without logo
      }

      // Load signature image
      Uint8List? signatureImageData;
      try {
        final ByteData signatureData = await rootBundle.load('assets/images/signature.png');
        signatureImageData = signatureData.buffer.asUint8List();
      } catch (imageError) {
        print("Error loading signature: $imageError");
        // Continue without signature
      }

      // Create a PDF certificate in landscape orientation
      final pdf = pw.Document();
      
      // Use landscape orientation for the certificate
      final pageTheme = pw.PageTheme(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
      );
      
      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (pw.Context context) {
            // Create premium border pattern
            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColors.blue300,
                  width: 3.0,
                ),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Container(
                margin: const pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.blue800,
                    width: 1.0,
                  ),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // Top section with logo - reduced size
                      if (logoImageData != null)
                        pw.Container(
                          height: 40,
                          child: pw.Image(
                            pw.MemoryImage(logoImageData),
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                      
                      // Certificate title with professional font
                      pw.Text(
                        'Certificate of Completion',
                        style: pw.TextStyle(
                          fontSize: 35,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                          font: pw.Font.times(),
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      
                      // Decorative line
                      pw.Container(
                        width: 200,
                        height: 2,
                        margin: const pw.EdgeInsets.symmetric(vertical: 10),
                        color: PdfColors.blue300,
                      ),
                      
                      // Middle section with recipient info
                      pw.Container(
                        margin: const pw.EdgeInsets.symmetric(vertical: 20),
                        child: pw.Column(
                          children: [
                            pw.SizedBox(height: 10),
                            pw.Text(
                              'This certificate is awarded to:',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontStyle: pw.FontStyle.italic,
                                color: PdfColors.grey800,
                              ),
                            ),
                            pw.SizedBox(height: 15),
                            pw.Text(
                              candidateName,
                              style: pw.TextStyle(
                                fontSize: 30,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue700,
                                font: pw.Font.times(),
                              ),
                            ),
                            pw.SizedBox(height: 15),
                            pw.Text(
                              'for the successful completion of the course',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontStyle: pw.FontStyle.italic,
                                color: PdfColors.grey800,
                              ),
                            ),
                            pw.SizedBox(height: 20),
                            pw.Text(
                              courseName.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Bottom section with date
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            'On $shortDate',
                            style: pw.TextStyle(
                              fontSize: 14,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(width: 5),
                          pw.Text(
                            'Course Duration: $courseDuration',
                            style: pw.TextStyle(
                              fontSize: 14,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      
                      // Signature section with improved styling - increased size
                      pw.Container(
                        margin: const pw.EdgeInsets.only(top: 20),
                        child: pw.Column(
                          children: [
                            // Signature image if available - increased size
                            if (signatureImageData != null)
                              pw.Container(
                                height: 50,
                                width: 150,
                                child: pw.Image(
                                  pw.MemoryImage(signatureImageData),
                                  fit: pw.BoxFit.contain,
                                ),
                              )
                            else
                              pw.Container(height: 50),
                              
                            // Signature line - wider
                            pw.Container(
                              width: 180,
                              height: 1,
                              color: PdfColors.black,
                              margin: const pw.EdgeInsets.only(bottom: 5),
                            ),
                            pw.Text(
                              'Muhammed Musthafa CMA, CSCA',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'CEO and Founder',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Certificate ID at the bottom
                      pw.Container(
                        alignment: pw.Alignment.bottomCenter,
                        margin: const pw.EdgeInsets.only(top: 10),
                        child: pw.Text(
                          'Certificate ID: $certificateId',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      
      // Generate file name based on course title and date
      final String sanitizedCourseName = courseName
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .toLowerCase();
      final String fileName = 'certificate_${sanitizedCourseName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      if (shouldShare) {
        // Use printing package to share PDF
        await Printing.sharePdf(
          bytes: pdfBytes, 
          filename: fileName,
        );
        
        Fluttertoast.showToast(
          msg: "Certificate ready to share",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
        );
      } else {
        // Save PDF to Downloads directory
        try {
          // Get the downloads directory
          Directory? downloadsDir;
          
          if (Platform.isAndroid) {
            // For Android, use the Downloads directory
            downloadsDir = Directory('/storage/emulated/0/Download');
            if (!await downloadsDir.exists()) {
              // Fallback to app documents directory
              downloadsDir = await getApplicationDocumentsDirectory();
            }
          } else {
            // For iOS, use the Documents directory
            downloadsDir = await getApplicationDocumentsDirectory();
          }
          
          // Create the file path
          final String filePath = '${downloadsDir.path}/$fileName';
          final File file = File(filePath);
          
          // Write the PDF bytes to the file
          await file.writeAsBytes(pdfBytes);
          
          Fluttertoast.showToast(
            msg: "Certificate saved to Downloads folder",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: const Color(0xFF10B981),
          );
          
          // Open the file
          await OpenFilex.open(filePath);
        } catch (saveError) {
          Fluttertoast.showToast(
            msg: "Error saving certificate: $saveError",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
          );
        }
      }
      
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: ${e.toString().substring(0, min(e.toString().length, 100))}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }
  
  // Add this utility function to get the minimum of two integers
  int min(int a, int b) {
    return a < b ? a : b;
  }
} 