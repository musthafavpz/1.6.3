<?php

namespace App\Http\Controllers;

use App\Models\CartItem;
use App\Models\Category;
use App\Models\Course;
use App\Models\Enrollment;
use App\Models\Language;
use App\Models\Live_class;
use App\Models\User;
use App\Models\Wishlist;
use App\Models\Certificate;
use App\Models\Lesson;
use App\Models\Question;
use App\Models\QuizSubmission;
use App\Models\Banner;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules;
use Illuminate\Auth\Events\Registered;
use Illuminate\Support\Str;
use App\Models\FileUploader;
use App\Models\Review;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Password;
use Illuminate\Validation\ValidationException;
use DB;
use Illuminate\Support\Facades\Log;

class ApiController extends Controller
{

    
    /**
     * Get quiz details for a specific lesson
     */
    public function getQuiz(Request $request, $lesson_id)
    {
        try {
            $user = $request->user();
            if (!$user) {
                return response()->json([
                    'status' => false,
                    'message' => 'User not authenticated'
                ], 401);
            }

            // Convert lesson_id to integer
            $lesson_id = (int)$lesson_id;

            // Log user and authentication info
            Log::info('Quiz request from user:', [
                'user_id' => $user->id,
                'lesson_id' => $lesson_id
            ]);
            
            // Check if lesson exists and is a quiz
            $quiz = Lesson::where('id', $lesson_id)
                          ->where('lesson_type', 'quiz')
                          ->first();
            
            if (!$quiz) {
                return response()->json([
                    'status' => false,
                    'message' => 'Quiz not found'
                ], 404);
            }
            
            // Get questions for this quiz
            $questions = Question::where('quiz_id', $lesson_id)
                                ->orderBy('sort', 'asc')
                                ->get();
            
            if ($questions->isEmpty()) {
                return response()->json([
                    'status' => false,
                    'message' => 'No questions found for this quiz',
                    'quiz_id' => $quiz->id,
                    'title' => 'Quiz',
                    'questions' => []
                ]);
            }
            
            // Format response for mobile app
            $formattedQuestions = $questions->map(function ($question) {
                // Handle the answer based on question type
                $answer = null;
                
                // Clean the question title from HTML tags
                $cleanTitle = strip_tags($question->title);
                
                try {
                    if (is_string($question->answer) && 
                        (strpos($question->answer, '[') === 0 || strpos($question->answer, '{') === 0)) {
                        // It's a JSON string, attempt to decode
                        $answer = json_decode($question->answer);
                        
                        // If JSON decode fails, use as is
                        if (json_last_error() !== JSON_ERROR_NONE) {
                            $answer = $question->answer;
                        }
                    } else {
                        // Not a JSON string, use as is
                        $answer = $question->answer;
                    }
                } catch (\Exception $e) {
                    Log::error('Error parsing question answer: ' . $e->getMessage());
                    $answer = $question->answer;
                }

                // Parse options
                $options = [];
                try {
                    if (is_string($question->options) && 
                        (strpos($question->options, '[') === 0 || strpos($question->options, '{') === 0)) {
                        // It's a JSON string, attempt to decode
                        $options = json_decode($question->options);
                        
                        // If JSON decode fails or result is not an array, create an empty array
                        if (json_last_error() !== JSON_ERROR_NONE || !is_array($options)) {
                            $options = [];
                        }
                    } else if (is_array($question->options)) {
                        $options = $question->options;
                    }
                } catch (\Exception $e) {
                    Log::error('Error parsing question options: ' . $e->getMessage());
                    $options = [];
                }
                
                // Log for debugging
                Log::info('Question ' . $question->id . ' formatted:', [
                    'title' => $cleanTitle,
                    'answer' => $answer,
                    'options' => $options
                ]);
                
                return [
                    'question_id' => (int)$question->id,
                    'question_text' => $cleanTitle,
                    'type' => $question->type,
                    'answer' => $answer,
                    'options' => $options,
                ];
            });
            
            // Get course details for this lesson
            $courseId = $quiz->course_id;
            $course = Course::find($courseId);
            
            return response()->json([
                'quiz_id' => (int)$quiz->id,
                'title' => $course ? $course->title . ' Quiz' : 'Quiz',
                'total_marks' => $questions->count(),
                'pass_mark' => 70, // Default passing mark (70%)
                'duration' => 30, // Default duration in minutes
                'questions' => $formattedQuestions
            ]);

        } catch (\Exception $e) {
            Log::error('Error in getQuiz: ' . $e->getMessage());
            Log::error('Stack trace: ' . $e->getTraceAsString());
            
            return response()->json([
                'status' => false,
                'message' => 'An error occurred: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Submit quiz answers
     */
    public function submitQuiz(Request $request)
    {
        try {
            $user = $request->user();
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not authenticated'
                ], 401);
            }
            
            // Log user and authentication info
            Log::info('Quiz submission from user:', [
                'user_id' => $user->id
            ]);
            
            // Log the incoming request for debugging
            Log::info('Quiz submission payload:', $request->all());
            
            $validatedData = $request->validate([
                'quiz_id' => 'required|integer',
                'lesson_id' => 'required|integer',
                'answers' => 'required|array',
                'correct_answer' => 'required|integer',
                'wrong_answer' => 'required|integer',
                'submits' => 'required|integer',
            ]);
            
            $quizId = (int)$validatedData['quiz_id'];
            $answers = $validatedData['answers'];
                
            Log::info('Quiz ID: ' . $quizId);
            Log::info('Answers:', (array) $answers);
            
            // Verify this is a valid quiz
            $quiz = Lesson::where('id', $quizId)
                          ->where('lesson_type', 'quiz')
                          ->first();
            
            if (!$quiz) {
                return response()->json([
                    'status' => false,
                    'message' => 'Quiz not found'
                ], 404);
            }
            
            // Check if course_id exists
            if (!$quiz->course_id) {
                Log::error('Quiz has no course_id: ', ['quiz_id' => $quizId]);
                return response()->json([
                    'status' => false,
                    'message' => 'Quiz has no associated course'
                ], 400);
            }
            
            // Process answers to determine correct and wrong answers
            $correctQuestionIds = [];
            $wrongQuestionIds = [];
            
            // Get questions for this quiz
            $questions = Question::where('quiz_id', $quizId)->get();
            Log::info('Questions found: ' . $questions->count());
            
            // Check each answer
            foreach ($answers as $questionId => $selectedAnswers) {
                // Make sure question ID is an integer to avoid type issues
                $questionIdInt = (int)$questionId;
                
                // Log the questionId and its type for debugging
                Log::info('Processing question ID: ' . $questionIdInt . ' (type: ' . gettype($questionIdInt) . ')');
                
                $question = $questions->firstWhere('id', $questionIdInt);
                
                if (!$question) {
                    Log::warning('Question not found:', ['question_id' => $questionIdInt]);
                    continue;
                }
                
                $correctAnswer = null;
                try {
                    // Attempt to decode answer if it's JSON
                    if (is_string($question->answer) && 
                        (strpos($question->answer, '[') === 0 || strpos($question->answer, '{') === 0)) {
                        $correctAnswer = json_decode($question->answer, true);
                    } else {
                        $correctAnswer = $question->answer;
                    }
                } catch (\Exception $e) {
                    Log::error('Error parsing answer for question ' . $questionIdInt . ': ' . $e->getMessage());
                    $correctAnswer = $question->answer;
                }
                
                // Get selected answer - first value in the array
                $selectedAnswer = isset($selectedAnswers[0]) ? $selectedAnswers[0] : null;
                
                // Check if answer is correct
                $isCorrect = false;
                if (is_array($correctAnswer)) {
                    $isCorrect = in_array($selectedAnswer, $correctAnswer);
                } else {
                    $isCorrect = $selectedAnswer == $correctAnswer;
                }
                
                // Add to correct or wrong arrays - ensure they're integers
                if ($isCorrect) {
                    $correctQuestionIds[] = $questionIdInt;
                } else {
                    $wrongQuestionIds[] = $questionIdInt;
                }
                
                Log::info('Question ' . $questionIdInt . ' result:', [
                    'selected' => $selectedAnswer,
                    'correct_answer' => $correctAnswer,
                    'is_correct' => $isCorrect ? 'yes' : 'no'
                ]);
            }
            
            // Debug the array types and values
            Log::info('Correct question IDs (before JSON):', [
                'count' => count($correctQuestionIds),
                'values' => $correctQuestionIds,
                'types' => array_map('gettype', $correctQuestionIds)
            ]);
            
            Log::info('Wrong question IDs (before JSON):', [
                'count' => count($wrongQuestionIds),
                'values' => $wrongQuestionIds,
                'types' => array_map('gettype', $wrongQuestionIds)
            ]);
            
            // Format data for database storage
            // Since we're using array casting in the model, we pass PHP arrays directly
            $correctAnswerData = !empty($correctQuestionIds) ? $correctQuestionIds : null;
            $wrongAnswerData = !empty($wrongQuestionIds) ? $wrongQuestionIds : null;
            
            // Convert all keys to strings to ensure proper JSON formatting
            $formattedAnswers = [];
            foreach ($answers as $questionId => $answer) {
                $formattedAnswers[(string)$questionId] = $answer;
            }
            
            Log::info('Data for database (raw PHP arrays):', [
                'correct_answer' => $correctAnswerData,
                'wrong_answer' => $wrongAnswerData,
                'submits' => $formattedAnswers
            ]);
            
            try {
                // Always create a new submission record instead of updating
                $submission = new QuizSubmission();
                $submission->quiz_id = $quizId;
                $submission->user_id = $user->id;
                $submission->correct_answer = $correctAnswerData;
                $submission->wrong_answer = $wrongAnswerData;
                $submission->submits = $formattedAnswers;
                $submission->save();
                
                Log::info('New quiz submission saved with ID: ' . $submission->id);
            } catch (\Exception $e) {
                Log::error('Error saving quiz submission: ' . $e->getMessage());
                Log::error('Error stack trace: ' . $e->getTraceAsString());
                return response()->json([
                    'success' => false,
                    'message' => 'Error saving quiz submission: ' . $e->getMessage()
                ], 500);
            }
                
            // Calculate percentage
            $totalQuestions = $questions->count();
            $correctCount = count($correctQuestionIds);
            $percentage = ($totalQuestions > 0) ? ($correctCount / $totalQuestions) * 100 : 0;
            $passStatus = ($percentage >= 70) ? 'passed' : 'failed'; // 70% pass threshold
            
            // Check if the user has passed this quiz before (even if they failed now)
            $previousPass = false;
            if ($passStatus === 'failed') {
                Log::info('Current quiz attempt failed. Checking previous submissions...');
                $previousSubmissions = QuizSubmission::where('quiz_id', $quizId)
                                                    ->where('user_id', $user->id)
                                                    ->get();
                
                Log::info('Found ' . $previousSubmissions->count() . ' previous submissions');
                
                foreach ($previousSubmissions as $prevSubmission) {
                    // Calculate percentage for this submission
                    $prevCorrectCount = is_array($prevSubmission->correct_answer) ? count($prevSubmission->correct_answer) : 0;
                    $prevWrongCount = is_array($prevSubmission->wrong_answer) ? count($prevSubmission->wrong_answer) : 0;
                    $prevTotalQuestions = $prevCorrectCount + $prevWrongCount;
                    
                    if ($prevTotalQuestions > 0) {
                        $prevPercentage = ($prevCorrectCount / $prevTotalQuestions) * 100;
                        Log::info('Previous submission ID: ' . $prevSubmission->id . ', percentage: ' . $prevPercentage);
                        
                        if ($prevPercentage >= 70) {
                            $previousPass = true;
                            Log::info('User previously passed this quiz with submission ID: ' . $prevSubmission->id);
                            break;
                        }
                    }
                }
            }
            
            // If user previously passed but failed now, set special flag to show in response
            if ($previousPass && $passStatus === 'failed') {
                $passStatus = 'previously_passed';
            }
            
            return response()->json([
                'success' => true,
                'id' => (int)$submission->id,
                'total_marks' => (int)$totalQuestions,
                'obtained_marks' => (int)$correctCount,
                'percentage' => (float)$percentage,
                'status' => $passStatus,
                'previously_passed' => $previousPass,
                'course_id' => $quiz->course_id,
                'lesson_id' => $quizId
            ]);
                
        } catch (ValidationException $e) {
            Log::error('Validation error in quiz submission: ' . json_encode($e->errors()));
            
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            Log::error('Error in quiz submission: ' . $e->getMessage());
            Log::error('Error stack trace: ' . $e->getTraceAsString());
                
            return response()->json([
                'success' => false,
                'message' => 'Error processing quiz: ' . $e->getMessage()
            ], 500);
        }
    }

    public function my_certificates(Request $request)
    {
        $user = $request->user();

        $certificates = Certificate::where('user_id', $user->id)->get();

        $data = $certificates->map(function($certificate) {
            return [
                'course_id' => $certificate->course_id,
                'certificate_url' => url('/certificate/' . $certificate->identifier),
                'created_at' => $certificate->created_at->toDateTimeString(),
            ];
        });

        return response()->json([
            'status' => true,
            'certificates' => $data
        ]);
    }

    //student login function
    public function login(Request $request)
    {
        $fields = $request->validate([
            'email' => 'required|string',
            'password' => 'required|string',
        ]);

        // Check email
        $user = User::where('email', $fields['email'])->where('status', 1)->first();

        // Check password
        if (!$user || !Hash::check($fields['password'], $user->password)) {
            if (isset($user) && $user->count() > 0) {
                return response([
                    'message' => 'Invalid credentials!',
                ], 401);
            } else {
                return response([
                    'message' => 'User not found!',
                ], 401);
            }
        } else if ($user->role == 'student') {

            // $user->tokens()->delete();

            $token = $user->createToken('auth-token')->plainTextToken;

            $user->photo = get_photo('user_image', $user->photo);

            $response = [
                'message' => 'Login successful',
                'user' => $user,
                'token' => $token,
            ];

            return response($response, 201);

        } else {

            //user not authorized
            return response()->json([
                'message' => 'User not found!',
            ], 400);
        }
    }

    public function signup(Request $request)
    {
        // return $request->all();
        $response = array();

        $rules = array(
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users'],
            'password' => ['required', 'confirmed', Rules\Password::defaults()]
        );
        $validator = Validator::make($request->all(), $rules);
        // if ($validator->fails()) {
        //     return json_encode(array('validationError' => $validator->getMessageBag()->toArray()));
        // }
        // if ($validator->fails()) {
        //     return response()->json(['validationError' => $validator->errors()], 422);
        // }
        // return $response;
        // $user = User::create([
        //     'name' => $request->name,
        //     'email' => $request->email,
        //     'role' => 'student',
        //     'password' => Hash::make($request->password),
        //     'status' => 1,
        // ]);
        $user_data = [
            'name' => $request->name,
            'email' => $request->email,
            'role' => 'student',
            'status' => 1,
            'password' => Hash::make($request->password),
        ];

        if(get_settings('student_email_verification') != 1){
            $user_data['email_verified_at'] = date('Y-m-d H:i:s');
        }

        $user = User::create($user_data);

        // if(get_settings('student_email_verification') == 1) {
        //     $user->sendEmailVerificationNotification();
        // }

        if ($user) {
            $response['success'] = true;
            $response['message'] = 'user create successfully';
        }
        // event(new Registered($user));

        return $response;
    }

    public function signup1(Request $request)
    {
        // send a type = registration with this api
        try {
            // Validation rules
            $rules = [
                'name' => ['required', 'string', 'max:255'],
                'email' => ['required', 'string', 'email', 'max:255', 'unique:users'],
                'password' => ['required', 'confirmed', Rules\Password::defaults()],
            ];

            // Validate the request
            $validator = Validator::make($request->all(), $rules);
            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'errors' => $validator->errors(),
                ], 422);
            }

            // Prepare user data
            $user_data = [
                'name' => $request->name,
                'email' => $request->email,
                'role' => 'student',
                'status' => 1,
                'password' => Hash::make($request->password),
            ];

            // Check if email verification is required
            $verificationRequired = get_settings('student_email_verification') ?? 0;
            if ($verificationRequired != 1) {
                $user_data['email_verified_at'] = now();
            }

            // Create the user
            $user = User::create($user_data);

            // Send email verification if required
            if ($verificationRequired == 1) {
                $user->sendEmailVerificationNotification();
            }

            // Return success response
            return response()->json([
                'success' => true,
                'message' => 'User created successfully',
                'data' => $user,
            ], 201);

        } catch (\Exception $e) {
            // Log the error for debugging
            Log::error('Error during signup: ' . $e->getMessage());

            // Return error response
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while creating the user.',
            ], 500);
        }
    }

    //student logout function
    public function logout(Request $request)
    {
        auth()->user()->tokens()->delete;

        return response()->json([
            'message' => 'Logged out successfully.',
        ], 201);
    }

    public function forgot_password(Request $request)
    {
        $response = [];

        $request->validate([
            'email' => ['required', 'email'],
        ]);

        $status = Password::sendResetLink($request->only('email'));

        if ($status == Password::RESET_LINK_SENT) {
            $response['success'] = true;
            $response['message'] = 'Reset Password Link sent successfully to your email.';
            return response()->json($response, 200);
        }

        $response['success'] = false;
        $response['message'] = 'Failed to send Reset Password Link. Please check the email and try again.';
        return response()->json($response, 400);
    }

    // update user data
    public function update_userdata(Request $request)
    {
        $response = array();
        $token = $request->bearerToken();

        if (isset($token) && $token != '') {
            $user_id = auth('sanctum')->user()->id;

            if ($request->name != "") {
                $data['name'] = htmlspecialchars($request->name, ENT_QUOTES, 'UTF-8');
            } else {
                $response['status'] = 'failed';
                $response['error_reason'] = 'Name cannot be empty';
                return $response;
            }

            $data['biography'] = $request->biography;
            $data['about'] = $request->about;
            $data['address'] = $request->address;
            $data['facebook'] = htmlspecialchars($request->facebook, ENT_QUOTES, 'UTF-8');
            $data['twitter'] = htmlspecialchars($request->twitter, ENT_QUOTES, 'UTF-8');
            $data['linkedin'] = htmlspecialchars($request->linkedin, ENT_QUOTES, 'UTF-8');

            if ($request->hasFile('photo')) {
                $file = $request->file('photo');
                $file_name = Str::random(20) . '.' . $file->getClientOriginalExtension();
                $path = 'assets/upload/users/' . auth('sanctum')->user()->role . '/' . $file_name;

                // Assuming FileUploader::upload() is a method that uploads the file
                FileUploader::upload($file, $path, null, null, 300);

                // Save the path to the database
                $data['photo'] = $path;
            }

            User::where('id', $user_id)->update($data);

            $user = auth('sanctum')->user();
            $user->photo = get_photo('user_image', $user->photo);

            $updated_user = User::find($user_id);
            $updated_user['photo'] = url('public/' . $updated_user['photo']);

            $response['status'] = 'success';
            $response['user'] = $updated_user;
            $response['error_reason'] = 'None';

        } else {
            $response['status'] = 'failed';
            $response['error_reason'] = 'Unauthorized login';
        }

        return $response;
    }

    //
    public function top_courses($top_course_id = "")
    {
        $query = Course::orderBy('id', 'desc')->where('status', 'active')->limit(10)->get();

        if ($top_course_id != "") {
            $query->where('id', $top_course_id);
        }

        $result = course_data($query);

        return $result;
    }

    public function all_categories()
    {
        $all_categories = array();
        $categories = Category::where('parent_id', 0)->get();
        foreach ($categories as $key => $category) {
            $all_categories[$key] = $category;
            $all_categories[$key]['thumbnail'] = get_photo('category_thumbnail', $category['thumbnail']);
            $all_categories[$key]['number_of_courses'] = get_category_wise_courses($category['id'])->count();

            $all_categories[$key]['number_of_sub_categories'] = $category->childs->count();

            // $sub_categories = $category->childs;
        }
        return $all_categories;
    }

    // Get categories
    public function categories($category_id = "")
    {
        if ($category_id != "") {
            $categories = Category::where('id', $category_id)->first();
        } else {
            $categories = Category::where('parent_id', 0)->get();
        }
        foreach ($categories as $key => $category) {
            $categories[$key]['thumbnail'] = get_photo('category_thumbnail', $category['thumbnail']);
            $categories[$key]['number_of_courses'] = get_category_wise_courses($category['id'])->count();

            $categories[$key]['number_of_sub_categories'] = $category->childs->count();
        }
        return $categories;
    }

    // Fetch all the categories
    public function category_details(Request $request)
    {

        $response = array();
        $categories = array();
        $categories = sub_categories($request->category_id);

        // $response['sub_categories'] = $categories;

        $response[0]['sub_categories'] = $categories;

        $courses = get_category_wise_courses($request->category_id);

        $response[0]['courses'] = course_data($courses);

        // foreach ($response as $key => $resp) {
        //     $response[$key]['sub_categories'] = $categories;
        // }

        return $response;

        // $response['courses'] = $result;

        // return $response;
    }

    // Fetch all the categories
    public function sub_categories($parent_category_id = "")
    {

        $categories = array();
        $categories = sub_categories($parent_category_id);

        return $categories;
    }

    // Fetch all the courses belong to a certain category
    public function category_wise_course(Request $request)
    {
        $category_id = $request->category_id;
        $courses = get_category_wise_courses($category_id);

        $result = course_data($courses);

        return $result;
    }
    // Fetch all the courses belong to a certain category
    public function category_subcategory_wise_course(Request $request)
    {
        $category_id = $request->category_id;
        $courses = get_category_wise_courses($category_id);
        $sub = Category::where('category_id', $category_id)->where('status', 'active')->get();

        $result = course_data($courses);

        return $result;
    }

    // Filter course
    public function filter_course(Request $request)
    {
        // $courses = $this->api_model->filter_course();
        // $this->set_response($courses, REST_Controller::HTTP_OK);

        $selected_category = $request->selected_category;
        $selected_price = $request->selected_price;
        $selected_level = $request->selected_level;
        $selected_language = $request->selected_language;
        $selected_rating = $request->selected_rating;
        $selected_search_string = ltrim(rtrim($request->selected_search_string));

        // $course_ids = array();

        $query = Course::query();

        if ($selected_search_string != "" && $selected_search_string != "null") {
            $query->where('title', $selected_search_string->id);
        }
        if ($selected_category != "all") {
            $query->where('category_id', $selected_category);
        }

        if ($selected_price != "all") {
            if ($selected_price == "paid") {
                $query->where('is_paid', 1);
            } elseif ($selected_price == "free") {
                $query->where('is_paid', 0)
                    ->orWhere('is_paid', null);
            }
        }

        if ($selected_level != "all") {
            $query->where('level', $selected_level);
        }

        if ($selected_language != "all") {
            $query->where('language', $selected_language);
        }

        $query->where('status', 'active');
        $courses = $query->get();

        // foreach ($courses as $course) {
        //     if ($selected_rating != "all") {
        //         $total_rating =  $this->crud_model->get_ratings('course', $course['id'], true)->row()->rating;
        //         $number_of_ratings = $this->crud_model->get_ratings('course', $course['id'])->num_rows();
        //         if ($number_of_ratings > 0) {
        //             $average_ceil_rating = ceil($total_rating / $number_of_ratings);
        //             if ($average_ceil_rating == $selected_rating) {
        //                 array_push($course_ids, $course['id']);
        //             }
        //         }
        //     } else {
        //         array_push($course_ids, $course['id']);
        //     }
        // }

        // This block of codes return the required data of courses
        $result = array();
        $result = course_data($courses);
        return $result;

    }

    // Fetch all the courses belong to a certain category
    public function languages()
    {
        $response = array();
        $languages = Language::select('name')->distinct()->get();

        foreach ($languages as $key => $language) {
            $response[$key]['id'] = $key + 1;
            $response[$key]['value'] = $language->name;
            $response[$key]['displayedValue'] = ucfirst($language->name);
        }

        return $response;
    }

    // Filter course
    public function courses_by_search_string(Request $request)
    {
        $search_string = $request->search_string;

        $courses = Course::where('title', 'LIKE', "%{$search_string}%")->where('status', 'active')->get();
        $response = course_data($courses);

        return $response;
    }

    // Course Details
    public function course_details_by_id(Request $request)
    {

        $response = array();

        $course_id = $request->course_id;

        $user = auth('sanctum')->user();
        $user_id = $user ? $user->id : 0;

        if ($user_id > 0) {
            $response = course_details_by_id($user_id, $course_id);
        } else {
            $response = course_details_by_id(0, $course_id);
        }
        return $response;

    }

    //Protected APIs. This APIs will require Authorization.
    // My Courses API
    public function my_courses(Request $request)
    {
        $token = $request->bearerToken();

        if (isset($token) && $token != '') {
            $user_id = auth('sanctum')->user()->id;

            $my_courses = array();
            $my_courses_ids = Enrollment::where('user_id', $user_id)->orderBy('id', 'desc')->get();
            foreach ($my_courses_ids as $my_courses_id) {
                $course_details = Course::find($my_courses_id['course_id']);
                if ($course_details)
                    array_push($my_courses, $course_details);
            }

            $my_courses = course_data($my_courses);

            foreach ($my_courses as $key => $my_course) {
                if (isset($my_course['id']) && $my_course['id'] > 0) {
                    $my_courses[$key]['completion'] = round(course_progress($my_course['id'], $user_id));
                    $my_courses[$key]['total_number_of_lessons'] = count(get_lessons('course', $my_course['id']));
                    $my_courses[$key]['total_number_of_completed_lessons'] = get_completed_number_of_lesson($user_id, 'course', $my_course['id']);
                } else {
                    unset($my_courses[$key]);
                }
            }

            return $my_courses;

        } else {

        }
    }

    // My Courses API
    public function my_wishlist(Request $request)
    {
        $token = $request->bearerToken();

        if (isset($token) && $token != '') {
            $user_id = auth('sanctum')->user()->id;
            $wishlist = Wishlist::where('user_id', $user_id)->pluck('course_id');
            $wishlists = json_decode($wishlist);

            if (sizeof($wishlists) > 0) {
                $courses = Course::whereIn('id', $wishlists)->get();
                $response = course_data($courses);
            } else {
                $response = array();
            }
        } else {

        }

        return $response;
    }

    // Remove from wishlist
    public function toggle_wishlist_items(Request $request)
    {
        $token = $request->bearerToken();

        if (isset($token) && $token != '') {
            $user_id = auth('sanctum')->user()->id;

            $status = "";
            $course_id = $request->course_id;
            $wishlists = array();
            $check_status = Wishlist::where('course_id', $course_id)->where('user_id', $user_id)->first();
            if (empty($check_status)) {
                $wishlist = new Wishlist();
                $wishlist->course_id = $request->course_id;
                $wishlist->user_id = $user_id;
                $wishlist->save();
                $status = "added";
            } else {
                Wishlist::where('user_id', $user_id)->where('course_id', $request->course_id)->delete();
                $status = "removed";
            }
            // $this->my_wishlist($user_id);
            $response['status'] = $status;
            return $response;

        } else {
            return response()->json([
                'message' => 'Please login first',
            ], 400);
        }
    }

    // Get all the sections
    public function sections(Request $request)
    {

        $token = $request->bearerToken();

        if (isset($token) && $token != '') {
            $user_id = auth('sanctum')->user()->id;
            $course_id = $request->course_id;
            $response = sections($course_id, $user_id);
        } else {

        }

        return $response;
    }

    // password reset
    public function update_password(Request $request)
    {

        $token = $request->bearerToken();
        $response = array();

        if (isset($token) && $token != '') {
            $auth = auth('sanctum')->user();

            // The passwords matches
            if (!Hash::check($request->get('current_password'), $auth->password)) {
                $response['status'] = 'failed';
                $response['message'] = 'Current Password is Invalid';

                return $response;
            }

            // Current password and new password same
            if (strcmp($request->get('current_password'), $request->new_password) == 0) {
                $response['status'] = 'failed';
                $response['message'] = 'New Password cannot be same as your current password.';

                return $response;
            }

            // Current password and new password same
            if (strcmp($request->get('confirm_password'), $request->new_password) != 0) {
                $response['status'] = 'failed';
                $response['message'] = 'New Password is not same as your confirm password.';

                return $response;
            }

            $user = User::find($auth->id);
            $user->password = Hash::make($request->new_password);
            $user->save();

            $response['status'] = 'success';
            $response['message'] = 'Password Changed Successfully';

            return $response;

        } else {
            $response['status'] = 'failed';
            $response['message'] = 'Please login first';

            return $response;
        }
    }

    public function account_disable(Request $request)
    {

        $token = $request->bearerToken();
        $response = array();

        if (isset($token) && $token != '') {
            $auth = auth('sanctum')->user();

            $account_password = $request->get('account_password');

            // The passwords matches
            if (Hash::check($account_password, $auth->password)) {
                User::where('id', $auth->id)->update([
                    'status' => 0,
                ]);
                $response['validity'] = 1;
                $response['message'] = 'Account has been removed';

            } else {
                $response['validity'] = 0;
                $response['message'] = 'Mismatch password';
            }
        }

        return $response;
    }

    public function cart_list(Request $request)
    {
        $token = $request->bearerToken();
        $cart_items = array();

        if (isset($token) && $token != '') {
            $auth = auth('sanctum')->user();
            $my_courses_ids = CartItem::where('user_id', $auth->id)->get();

            foreach ($my_courses_ids as $my_courses_id) {
                $course_details = Course::find($my_courses_id['course_id']);
                array_push($cart_items, $course_details);
            }

            $cart_items = course_data($cart_items);
        }

        return $cart_items;
    }

    // Toggle from cart list
    public function toggle_cart_items(Request $request)
    {
        $token = $request->bearerToken();

        if (isset($token) && $token != '') {
            $user_id = auth('sanctum')->user()->id;

            $status = "";
            $course_id = $request->course_id;
            $cart_items = array();
            $check_status = CartItem::where('course_id', $course_id)->where('user_id', $user_id)->first();
            if (empty($check_status)) {
                $cart_item = new CartItem();
                $cart_item->course_id = $request->course_id;
                $cart_item->user_id = $user_id;
                $cart_item->save();
                $status = "added";
            } else {
                CartItem::where('user_id', $user_id)->where('course_id', $request->course_id)->delete();
                
                
                                $status = "removed";
            }
            // $this->my_wishlist($user_id);
            $response['status'] = $status;
            return $response;

        }
    }

    public function save_course_progress(Request $request)
    {
        $token = $request->bearerToken();

        if (isset($token) && $token != '') {
            $user_id = auth('sanctum')->user()->id;

            $lessons = get_lessons('lesson', $request->lesson_id);

            update_watch_history_manually($request->lesson_id, $lessons[0]->course_id, $user_id);

            return course_completion_data($lessons[0]->course_id, $user_id);
        }
    }

    public function live_class_schedules(Request $request)
    {
        $response = array();

        $classes = array();

        $live_classes = Live_class::where('course_id', $request->course_id)->orderBy('class_date_and_time', 'desc')->get();

        foreach ($live_classes as $key => $live_class) {
            $additional_info = json_decode($live_class->additional_info, true);

            $classes[$key]['class_topic'] = $live_class->class_topic;
            $classes[$key]['provider'] = $live_class->provider;
            $classes[$key]['note'] = $live_class->note;
            $classes[$key]['class_date_and_time'] = $live_class->class_date_and_time;
            $classes[$key]['meeting_id'] = $additional_info['id'];
            $classes[$key]['meeting_password'] = $additional_info['password'];
            $classes[$key]['start_url'] = $additional_info['start_url'];
            $classes[$key]['join_url'] = $additional_info['join_url'];
        }

        $response['live_classes'] = $classes;

        $response['zoom_sdk'] = get_settings('zoom_web_sdk');
        $response['zoom_sdk_client_id'] = get_settings('zoom_sdk_client_id');
        $response['zoom_sdk_client_secret'] = get_settings('zoom_sdk_client_secret');

        return $response;
    }

    public function payment(Request $request)
    {
        $response = array();
        $token = $request->bearerToken();

        if (isset($token) && $token != '') {
            $user = auth('sanctum')->user();
            Auth::login($user);
        }

        if ($request->app_url) {
            session(['app_url' => $request->app_url . '://']);
        }

        return redirect(route('payment'));
        // return $response;
    }
    
    public function free_course_enroll(Request $request, $course_id)
    {
        $response = array();
        $token = $request->bearerToken();

        if (isset($token) && $token != '') {
            $user_id = auth('sanctum')->user()->id;
            $check = Enrollment::where('course_id', $course_id)->where('user_id', $user_id)->count();
            if ($check == 0) {
                $enrollment['user_id'] = auth('sanctum')->user()->id;
                $enrollment['course_id'] = $course_id;
                $enrollment['enrollment_type'] = 'free';
                $enrollment['entry_date'] = time();
                $enrollment['expiry_date'] = null;
                $done = Enrollment::insert($enrollment);
                if ($done) {
                    $response['status'] = true;
                    $response['message'] = "Course Successfully enrolled";
                } else {
                    $response['status'] = false;
                    $response['message'] = "Some error occur,Try again";
                }
            }

        } else {
            $response['status'] = false;
            $response['message'] = "Undefined authentication";
        }

        return $response;
    }
    
    public function cart_tools(Request $request)
    {
        $response = array();
        $token = $request->bearerToken();

        if (isset($token) && $token != '') {
            $response['course_selling_tax'] = get_settings('course_selling_tax');
            $response['currency_position'] = get_settings('currency_position');
            $response['currency_symbol'] = DB::table('currencies')->where('code', get_settings('system_currency'))->value('symbol');
        } else {
            $response['status'] = "Not Authorized Credential";
        }
        return $response;
    }

    /**
     * Helper function to update watch history manually
     */
    private function update_watch_history_manually($lesson_id, $course_id, $user_id) 
    {
        // Validate inputs
        if (!$lesson_id || !$course_id || !$user_id) {
            Log::error('Missing required parameters for update_watch_history_manually', [
                'lesson_id' => $lesson_id,
                'course_id' => $course_id,
                'user_id' => $user_id
            ]);
            throw new \Exception('Missing required parameters for updating watch history');
        }

        try {
            // Mark lesson as completed
            $lesson_status = DB::table('watch_histories')
                ->where('lesson_id', $lesson_id)
                ->where('user_id', $user_id)
                ->first();
            
            if (!$lesson_status) {
                DB::table('watch_histories')->insert([
                    'lesson_id' => $lesson_id,
                    'user_id' => $user_id,
                    'course_id' => $course_id,
                    'watched' => 1,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            } else {
                DB::table('watch_histories')
                    ->where('lesson_id', $lesson_id)
                    ->where('user_id', $user_id)
                    ->update([
                        'watched' => 1,
                        'updated_at' => now(),
                    ]);
            }
            
            // Update course progress
            $course_progress = course_completion_data($course_id, $user_id);
            
            return $course_progress;
        } catch (\Exception $e) {
            Log::error('Error in update_watch_history_manually: ' . $e->getMessage());
            throw $e;
        }
    }

    /**
     * Get all active banners for the app
     */
    public function getBanners(Request $request)
    {
        try {
            $banners = Banner::where('is_active', true)
                ->orderBy('sort_order', 'asc')
                ->get();

            // Format the banners for the mobile app
            $formattedBanners = $banners->map(function ($banner) {
                return [
                    'id' => $banner->id,
                    'title' => $banner->title,
                    'subtitle' => $banner->subtitle,
                    'description' => $banner->description,
                    'image_path' => get_photo('banner_image', $banner->image_path),
                    'background_type' => $banner->background_type,
                    'background_value' => $banner->background_value,
                    'gradient_colors' => [
                        $banner->gradient_start_color,
                        $banner->gradient_end_color
                    ],
                    'enroll_button' => [
                        'text' => $banner->enroll_button_text,
                        'url' => $banner->enroll_button_url
                    ],
                    'preview_button' => [
                        'text' => $banner->preview_button_text,
                        'video_id' => $banner->preview_video_id
                    ]
                ];
            });

            return response()->json([
                'status' => true,
                'banners' => $formattedBanners
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching banners: ' . $e->getMessage());
            return response()->json([
                'status' => false,
                'message' => 'Failed to fetch banners'
            ], 500);
        }
    }

    /**
     * Admin: Get all banners
     */
    public function getAllBanners(Request $request)
    {
        try {
            // Check if user is admin
            $user = $request->user();
            if ($user->role !== 'admin') {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized access'
                ], 403);
            }

            $banners = Banner::orderBy('sort_order', 'asc')->get();
            
            return response()->json([
                'status' => true,
                'banners' => $banners
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching all banners: ' . $e->getMessage());
            return response()->json([
                'status' => false,
                'message' => 'Failed to fetch banners'
            ], 500);
        }
    }

    /**
     * Admin: Get a specific banner
     */
    public function getBanner(Request $request, $id)
    {
        try {
            // Check if user is admin
            $user = $request->user();
            if ($user->role !== 'admin') {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized access'
                ], 403);
            }

            $banner = Banner::find($id);
            
            if (!$banner) {
                return response()->json([
                    'status' => false,
                    'message' => 'Banner not found'
                ], 404);
            }

            return response()->json([
                'status' => true,
                'banner' => $banner
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching banner: ' . $e->getMessage());
            return response()->json([
                'status' => false,
                'message' => 'Failed to fetch banner'
            ], 500);
        }
    }

    /**
     * Admin: Create a new banner
     */
    public function createBanner(Request $request)
    {
        try {
            // Check if user is admin
            $user = $request->user();
            if ($user->role !== 'admin') {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized access'
                ], 403);
            }

            // Validate request data
            $validatedData = $request->validate([
                'title' => 'required|string|max:255',
                'subtitle' => 'required|string|max:255',
                'description' => 'nullable|string',
                'background_type' => 'nullable|in:color,image',
                'background_value' => 'nullable|string|max:255',
                'gradient_start_color' => 'nullable|string|max:20',
                'gradient_end_color' => 'nullable|string|max:20',
                'enroll_button_text' => 'nullable|string|max:50',
                'enroll_button_url' => 'nullable|string|max:255',
                'preview_button_text' => 'nullable|string|max:50',
                'preview_video_id' => 'nullable|string|max:100',
                'sort_order' => 'nullable|integer',
                'is_active' => 'nullable|boolean',
            ]);

            // Handle image upload if present
            if ($request->hasFile('image')) {
                $file = $request->file('image');
                $fileName = 'banner_' . time() . '.' . $file->getClientOriginalExtension();
                $path = 'assets/upload/banners/' . $fileName;
                
                // Upload the file
                FileUploader::upload($file, $path, null, null, 800);
                $validatedData['image_path'] = $path;
            }

            // Create banner
            $banner = Banner::create($validatedData);

            return response()->json([
                'status' => true,
                'message' => 'Banner created successfully',
                'banner' => $banner
            ], 201);
        } catch (\Exception $e) {
            Log::error('Error creating banner: ' . $e->getMessage());
            return response()->json([
                'status' => false,
                'message' => 'Failed to create banner: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Admin: Update an existing banner
     */
    public function updateBanner(Request $request, $id)
    {
        try {
            // Check if user is admin
            $user = $request->user();
            if ($user->role !== 'admin') {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized access'
                ], 403);
            }

            // Find banner
            $banner = Banner::find($id);
            if (!$banner) {
                return response()->json([
                    'status' => false,
                    'message' => 'Banner not found'
                ], 404);
            }

            // Validate request data
            $validatedData = $request->validate([
                'title' => 'nullable|string|max:255',
                'subtitle' => 'nullable|string|max:255',
                'description' => 'nullable|string',
                'background_type' => 'nullable|in:color,image',
                'background_value' => 'nullable|string|max:255',
                'gradient_start_color' => 'nullable|string|max:20',
                'gradient_end_color' => 'nullable|string|max:20',
                'enroll_button_text' => 'nullable|string|max:50',
                'enroll_button_url' => 'nullable|string|max:255',
                'preview_button_text' => 'nullable|string|max:50',
                'preview_video_id' => 'nullable|string|max:100',
                'sort_order' => 'nullable|integer',
                'is_active' => 'nullable|boolean',
            ]);

            // Handle image upload if present
            if ($request->hasFile('image')) {
                // Delete old image if exists
                if ($banner->image_path) {
                    // Add code to delete old file if needed
                }

                $file = $request->file('image');
                $fileName = 'banner_' . time() . '.' . $file->getClientOriginalExtension();
                $path = 'assets/upload/banners/' . $fileName;
                
                // Upload the file
                FileUploader::upload($file, $path, null, null, 800);
                $validatedData['image_path'] = $path;
            }

            // Update banner
            $banner->update($validatedData);

            return response()->json([
                'status' => true,
                'message' => 'Banner updated successfully',
                'banner' => $banner
            ]);
        } catch (\Exception $e) {
            Log::error('Error updating banner: ' . $e->getMessage());
            return response()->json([
                'status' => false,
                'message' => 'Failed to update banner: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Admin: Delete a banner
     */
    public function deleteBanner(Request $request, $id)
    {
        try {
            // Check if user is admin
            $user = $request->user();
            if ($user->role !== 'admin') {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized access'
                ], 403);
            }

            // Find banner
            $banner = Banner::find($id);
            if (!$banner) {
                return response()->json([
                    'status' => false,
                    'message' => 'Banner not found'
                ], 404);
            }

            // Delete image if exists
            if ($banner->image_path) {
                // Add code to delete file if needed
            }

            // Delete banner
            $banner->delete();

            return response()->json([
                'status' => true,
                'message' => 'Banner deleted successfully'
            ]);
        } catch (\Exception $e) {
            Log::error('Error deleting banner: ' . $e->getMessage());
            return response()->json([
                'status' => false,
                'message' => 'Failed to delete banner'
            ], 500);
        }
    }

    /**
     * Admin: Reorder banners
     */
    public function reorderBanners(Request $request)
    {
        try {
            // Check if user is admin
            $user = $request->user();
            if ($user->role !== 'admin') {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized access'
                ], 403);
            }

            // Validate request data
            $validatedData = $request->validate([
                'banners' => 'required|array',
                'banners.*.id' => 'required|integer|exists:banners,id',
                'banners.*.sort_order' => 'required|integer',
            ]);

            // Update sort order for each banner
            foreach ($validatedData['banners'] as $bannerData) {
                Banner::where('id', $bannerData['id'])->update([
                    'sort_order' => $bannerData['sort_order']
                ]);
            }

            return response()->json([
                'status' => true,
                'message' => 'Banners reordered successfully'
            ]);
        } catch (\Exception $e) {
            Log::error('Error reordering banners: ' . $e->getMessage());
            return response()->json([
                'status' => false,
                'message' => 'Failed to reorder banners'
            ], 500);
        }
    }
}