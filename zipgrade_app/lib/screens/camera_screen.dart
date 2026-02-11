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

    _controller = CameraController(firstCamera, ResolutionPreset.medium);

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
    request.fields['score'] =
        '0'; // Placeholder, will be calculated by server in real app or update later
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
      appBar: AppBar(title: Text('Scan: ${widget.exam.name}')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller!),
                // Overlay for alignment
                Center(
                  child: Container(
                    width: 300,
                    height: 500,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      onPressed: _takePictureAndUpload,
                      child: const Icon(Icons.camera),
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
