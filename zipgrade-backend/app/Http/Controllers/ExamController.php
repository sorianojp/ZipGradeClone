<?php

namespace App\Http\Controllers;

use App\Models\Exam;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ExamController extends Controller
{
    public function index()
    {
        return Auth::user()->exams;
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'date' => 'nullable|date',
            'omr_code' => 'required|in:20,50,100',
        ]);

        $exam = Auth::user()->exams()->create($request->all());

        return response()->json($exam, 201);
    }

    public function show($id)
    {
        return Auth::user()->exams()->with('questions')->findOrFail($id);
    }

    public function update(Request $request, $id)
    {
        $exam = Auth::user()->exams()->findOrFail($id);

        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'date' => 'nullable|date',
            'omr_code' => 'sometimes|required|in:20,50,100',
        ]);

        $exam->update($request->all());

        return response()->json($exam);
    }

    public function destroy($id)
    {
        $exam = Auth::user()->exams()->findOrFail($id);
        $exam->delete();

        return response()->json(null, 204);
    }
    
    // Helper to add questions in bulk
    public function addQuestions(Request $request, $id)
    {
        $exam = Auth::user()->exams()->findOrFail($id);
        
        $request->validate([
            'questions' => 'required|array',
            'questions.*.question_number' => 'required|integer',
            'questions.*.correct_answer' => 'required|string|max:1',
            'questions.*.points' => 'integer',
        ]);

        // Delete existing or update? For simplicity, let's wipe and replace or just add.
        // Let's assume this endpoint sets the key.
        $exam->questions()->delete();
        $exam->questions()->createMany($request->questions);

        return response()->json($exam->load('questions'));
    }
}
