import 'package:flutter/material.dart';

class ScanResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const ScanResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final score = result['percentage'];
    final totalQuestions = result['total_questions'];
    final rawScore = result['raw_score'];
    final List<dynamic> answers = result['student_answers'] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Result')),
      body: Column(
        children: [
          // Score Header
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blueAccent,
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  '${(score as num).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$rawScore / $totalQuestions Correct',
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                if (result['debug_image_url'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.image_search),
                      label: const Text('View Debug Image'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            child: Image.network(result['debug_image_url']),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Answers List
          Expanded(
            child: ListView.builder(
              itemCount: answers.length,
              itemBuilder: (context, index) {
                final answer = answers[index];
                final isCorrect =
                    answer['is_correct'] == 1 || answer['is_correct'] == true;
                final marked = answer['marked_answer'] ?? '-';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCorrect ? Colors.green : Colors.red,
                    child: Icon(
                      isCorrect ? Icons.check : Icons.close,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    'Question ${index + 1}',
                  ), // We need actual question number if possible, but index + 1 is okay for now
                  subtitle: Text('Marked: $marked'),
                  trailing: isCorrect
                      ? const Text(
                          'Correct',
                          style: TextStyle(color: Colors.green),
                        )
                      : Text(
                          'Incorrect (Ans: ${answer['question'] != null ? answer['question']['correct_answer'] : '?'})',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Pop back to Dashboard or Camera
                Navigator.of(context).pop();
              },
              child: const Text('Scan Another'),
            ),
          ),
        ],
      ),
    );
  }
}
