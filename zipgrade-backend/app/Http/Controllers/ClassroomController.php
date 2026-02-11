<?php

namespace App\Http\Controllers;

use App\Models\Classroom;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ClassroomController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        return Auth::user()->classrooms;
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'section' => 'nullable|string|max:255',
        ]);

        $classroom = Auth::user()->classrooms()->create($request->all());

        return response()->json($classroom, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show($id)
    {
        $classroom = Auth::user()->classrooms()->with('students')->findOrFail($id);
        return $classroom;
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, $id)
    {
        $classroom = Auth::user()->classrooms()->findOrFail($id);

        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'section' => 'nullable|string|max:255',
        ]);

        $classroom->update($request->all());

        return response()->json($classroom);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy($id)
    {
        $classroom = Auth::user()->classrooms()->findOrFail($id);
        $classroom->delete();

        return response()->json(null, 204);
    }
}
