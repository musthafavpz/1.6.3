<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Quiz extends Model
{
    use HasFactory;
    
    protected $fillable = [
        'title',
        'lesson_id',
        'course_id',
        'duration',
        'pass_mark',
        'status',
    ];
    
    /**
     * Get the questions for the quiz.
     */
    public function questions()
    {
        return $this->hasMany(Question::class);
    }
    
    /**
     * Get the submissions for the quiz.
     */
    public function submissions()
    {
        return $this->hasMany(QuizSubmission::class);
    }
    
    /**
     * Get the lesson associated with the quiz.
     */
    public function lesson()
    {
        return $this->belongsTo(Lesson::class);
    }
} 