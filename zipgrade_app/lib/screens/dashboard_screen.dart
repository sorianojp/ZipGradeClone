import 'package:flutter/material.dart';
import 'package:zipgrade_app/api/api_service.dart';
import 'package:zipgrade_app/models/exam.dart';
import 'package:zipgrade_app/screens/camera_screen.dart';
import 'package:zipgrade_app/screens/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Exam> _exams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    try {
      final List<dynamic> data = await ApiService.get('exams');
      setState(() {
        _exams = data.map((json) => Exam.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('401') ||
            e.toString().contains('Unauthenticated')) {
          _logout();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to load exams: $e')));
        }
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Exams'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExams,
              child: ListView.builder(
                itemCount: _exams.length,
                itemBuilder: (context, index) {
                  final exam = _exams[index];
                  return Card(
                    child: ListTile(
                      title: Text(exam.name),
                      subtitle: Text('Format: ${exam.omrCode} questions'),
                      trailing: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CameraScreen(exam: exam),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
