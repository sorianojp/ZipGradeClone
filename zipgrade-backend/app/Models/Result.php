<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Result extends Model
{
    use HasFactory;

    protected $fillable = ['exam_id', 'student_identifier', 'percentage', 'total_questions', 'raw_score', 'scan_image_path'];

    public function exam()
    {
        return $this->belongsTo(Exam::class);
    }



    public function studentAnswers()
    {
        return $this->hasMany(StudentAnswer::class);
    }
}
