<?php

namespace App\Http\Controllers;

use App\Models\Student;
use App\Models\Classroom;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class StudentController extends Controller
{
    public function index()
    {
        // Return students from all of user's classrooms
        // Query: Get students where exists (classroom_student where classroom.user_id = auth_id)
        return Student::whereHas('classrooms', function($query) {
            $query->where('user_id', Auth::id());
        })->get();
    }

    public function store(Request $request)
    {
        $request->validate([
            'first_name' => 'required|string',
            'last_name' => 'required|string',
            'external_id' => 'nullable|string',
            'classroom_id' => 'required|exists:classrooms,id',
        ]);

        // Verify user owns the classroom
        $classroom = Auth::user()->classrooms()->findOrFail($request->classroom_id);

        $student = Student::create($request->only(['first_name', 'last_name', 'external_id']));
        
        $student->classrooms()->attach($classroom->id);

        return response()->json($student, 201);
    }

    public function show($id)
    {
        // Ensure student belongs to one of user's classrooms
        $student = Student::whereHas('classrooms', function($query) {
            $query->where('user_id', Auth::id());
        })->with('classrooms')->findOrFail($id);

        return $student;
    }
}
