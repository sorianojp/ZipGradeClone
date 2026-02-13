import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:zipgrade_app/api/api_service.dart';
import 'package:zipgrade_app/screens/scan_result_screen.dart';
import 'package:zipgrade_app/models/exam.dart';
import 'package:http/http.dart' as http;

class CameraScreen extends StatefulWidget {
  final Exam exam;

  const CameraScreen({super.key, required this.exam});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(firstCamera, ResolutionPreset.veryHigh);

    _initializeControllerFuture = _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePictureAndUpload() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await _initializeControllerFuture;

      final image = await _controller!.takePicture();

      if (!mounted) return;

      // Upload logic
      await _uploadScan(image.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan uploaded successfully!')),
        );
      }
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _uploadScan(String imagePath) async {
    // Construct Multipart Request
    final uri = Uri.parse('${ApiService.baseUrl}/results');
    final request = http.MultipartRequest('POST', uri);

    // Add Headers
    final headers = await ApiService.getHeaders();
    request.headers.addAll(headers);
    // Remove Content-Type from headers as MultipartRequest sets it
    request.headers.remove('Content-Type');

    // Add Fields
    request.fields['exam_id'] = widget.exam.id.toString();
    // percentage calculated on server, but field name changed
    // request.fields['percentage'] = '0';
    request.fields['total_questions'] = widget.exam.omrCode;
    request.fields['raw_score'] = '0';

    // Add Dummy Answers for now as we don't have OMR yet
    // In a real scenario, OMR happens here or on server
    // logic: answers[0][question_id]=1&answers[0][marked_answer]=A
    // Sending empty answers for now or basic structure
    // request.fields['answers'] = '[]'; // API expects array, Multipart handles array fields tricky.
    // Let's simplified API to accept JSON string for answers if needed, or loop.
    // For this prototype, I'll skip sending answers and modify backend validation if needed,
    // OR just send a dummy result.

    // Changing ResultController to nullable answers or valid request.
    // Let's send one dummy answer.
    // request.fields['answers[0][question_id]'] = '1';

    // Actually, passing complex arrays in Multipart is annoying.
    // It's better to process OMR on device, then send JSON result.
    // If I upload image, I expect server to process.
    // Since I implemented `ResultController` to expect answers, I should probably adjust it to optional.

    // For now, let's just upload the image.
    // I need to adjust ResultController validation to make 'answers' nullable or empty allowed.

    request.files.add(
      await http.MultipartFile.fromPath('scan_image', imagePath),
    );

    final response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final respStr = await response.stream.bytesToString();
      final resultData = jsonDecode(respStr);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanResultScreen(result: resultData),
          ),
        );
      }
    } else {
      final respStr = await response.stream.bytesToString();
      throw Exception('Upload failed: ${response.statusCode} $respStr');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final size = MediaQuery.of(context).size;
            var scale = size.aspectRatio * _controller!.value.aspectRatio;

            // to prevent scaling down, invert the value
            if (scale < 1) scale = 1 / scale;

            return Stack(
              fit: StackFit.expand,
              children: [
                Transform.scale(
                  scale: scale,
                  child: Center(child: CameraPreview(_controller!)),
                ),
                // Overlay for alignment (Corner Guides)
                Center(
                  child: SizedBox(
                    width: 300, // Fixed width
                    height:
                        300 * (297 / 210), // A4 Aspect Ratio height ~ 424.28
                    child: CustomPaint(painter: ScannerOverlayPainter()),
                  ),
                ),
                // Top controls (Back button & Title)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Scan: ${widget.exam.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3.0,
                                color: Colors.black,
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Loading indicator
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                // Bottom controls (Capture button)
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _takePictureAndUpload,
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: Colors.white24,
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

// Add this class at the bottom of camera_screen.dart or in a separate file
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final double cornerLength = 40;

    final path = Path();

    // Top-left
    path.moveTo(0, cornerLength);
    path.lineTo(0, 0);
    path.lineTo(cornerLength, 0);

    // Top-right
    path.moveTo(size.width - cornerLength, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, cornerLength);

    // Bottom-right
    path.moveTo(size.width, size.height - cornerLength);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - cornerLength, size.height);

    // Bottom-left
    path.moveTo(cornerLength, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
