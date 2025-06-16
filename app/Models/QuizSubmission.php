<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class QuizSubmission extends Model
{
    use HasFactory;
    
    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'quiz_id',
        'user_id',
        'correct_answer',
        'wrong_answer',
        'submits',
    ];
    
    /**
     * The attributes that should be cast.
     *
     * @var array
     */
    protected $casts = [
        'correct_answer' => 'array',
        'wrong_answer' => 'array',
        'submits' => 'array',
    ];
    
    /**
     * Get the user that owns the quiz submission.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }
    
    /**
     * Get the quiz that owns the submission.
     */
    public function quiz()
    {
        return $this->belongsTo(Lesson::class, 'quiz_id');
    }
} 