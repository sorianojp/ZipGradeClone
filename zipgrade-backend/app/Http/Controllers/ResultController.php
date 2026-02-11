<?php

namespace App\Http\Controllers;

use App\Models\Result;
use App\Models\Exam;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\Process\Process;
use Symfony\Component\Process\Exception\ProcessFailedException;

class ResultController extends Controller
{
    public function index()
    {
        // Return results for exams owned by user
        return Result::whereHas('exam', function($query) {
            $query->where('user_id', Auth::id());
        })->with(['student', 'exam'])->latest()->get();
    }

    public function store(Request $request)
    {
        $request->validate([
            'exam_id' => 'required|exists:exams,id',
            'student_id' => 'nullable|exists:students,id',
            // Score fields optional now as they will be calculated
            'score' => 'nullable|numeric',
            'total_questions' => 'required|integer',
            'raw_score' => 'nullable|integer',
            'answers' => 'nullable|array', 
            'scan_image' => 'required|image',
        ]);

        // Verify exam ownership
        $exam = Auth::user()->exams()->with('questions')->findOrFail($request->exam_id);

        $imagePath = $request->file('scan_image')->store('scans', 'public');
        $fullPath = storage_path('app/public/' . $imagePath);

        // Run OMR Script
        $process = new Process(['python3', base_path('process_omr.py'), $fullPath]);
        $process->run();

        // executes after the command finishes
        if (!$process->isSuccessful()) {
            // Fallback if python missing or failed
            // throw new ProcessFailedException($process);
            // Log error
            \Log::error('OMR Error: ' . $process->getErrorOutput());
            
            // Allow manual grading if OMR fails? 
            // Return error for now to debug
            return response()->json(['error' => 'OMR Processing Failed:' . $process->getErrorOutput()], 500);
        }

        $output = $process->getOutput();
        $omrResult = json_decode($output, true);

        if (isset($omrResult['error'])) {
             return response()->json(['error' => 'OMR Logic Error: ' . $omrResult['error']], 500);
        }
        
        // Calculate Score
        $detectedAnswers = $omrResult['answers'] ?? []; // Map from OMR
        // We need to map `question_number` from OMR to `question_id` from DB.
        
        $questions = $exam->questions->keyBy('question_number');
        $score = 0;
        $totalPoints = 0; // Or just count correct inputs
        $rawScore = 0;
        $studentAnswers = [];

        foreach ($detectedAnswers as $detected) {
            $qNum = $detected['question_number'];
            if (isset($questions[$qNum])) {
                $question = $questions[$qNum];
                $isCorrect = ($detected['marked_answer'] === $question->correct_answer);
                
                if ($isCorrect) {
                     $rawScore++;
                     $score += $question->points; // Assuming 1 point per Q usually
                }
                
                $studentAnswers[] = [
                    'question_id' => $question->id,
                    'marked_answer' => $detected['marked_answer'],
                    'is_correct' => $isCorrect
                ];
            }
        }
        
        // Calculate percentage?
        // Assuming total possible points = number of questions * 1 for simplicity
        $totalPossible = $exam->questions()->sum('points');
        $finalScore = ($totalPossible > 0) ? ($score / $totalPossible) * 100 : 0;


        $result = $exam->results()->create([
            'student_id' => $request->student_id,
            'score' => $finalScore,
            'total_questions' => $request->total_questions,
            'raw_score' => $rawScore,
            'scan_image_path' => $imagePath,
        ]);

        $result->studentAnswers()->createMany($studentAnswers);
        
        $response = $result->load('studentAnswers.question')->toArray();
        if (isset($omrResult['debug_image'])) {
            $response['debug_image_url'] = asset('storage/scans/' . $omrResult['debug_image']);
        }

        return response()->json($response, 201);
    }

    public function show($id)
    {
        return Result::whereHas('exam', function($query) {
            $query->where('user_id', Auth::id());
        })->with(['student', 'studentAnswers'])->findOrFail($id);
    }
}
