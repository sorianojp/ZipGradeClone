<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Question extends Model
{
    use HasFactory;

    protected $fillable = ['exam_id', 'question_number', 'correct_answer', 'points'];

    public function exam()
    {
        return $this->belongsTo(Exam::class);
    }
}
