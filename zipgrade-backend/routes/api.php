<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;

use App\Http\Controllers\ExamController;
use App\Http\Controllers\ResultController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'user']);

    // Route::apiResource('classrooms', ClassroomController::class);
    // Route::apiResource('students', StudentController::class);
    Route::apiResource('exams', ExamController::class);
    Route::post('exams/{exam}/questions', [ExamController::class, 'addQuestions']);
    Route::apiResource('results', ResultController::class);
});
