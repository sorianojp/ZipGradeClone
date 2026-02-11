<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    use HasFactory;

    protected $fillable = ['first_name', 'last_name', 'external_id'];

    public function classrooms()
    {
        return $this->belongsToMany(Classroom::class);
    }

    public function results()
    {
        return $this->hasMany(Result::class);
    }
}
