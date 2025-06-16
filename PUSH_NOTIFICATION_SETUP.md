# Push Notification Setup Guide

This guide explains how to set up Firebase Cloud Messaging (FCM) for your Academy LMS app, both on the client (Flutter) and server (Laravel) sides.

## Client-Side Setup (Flutter App)

The Flutter app has been updated with the necessary components to handle push notifications:

1. Added Firebase packages: `firebase_core`, `firebase_messaging`, and `flutter_local_notifications`
2. Created a `NotificationService` class to handle FCM setup and notification management
3. Updated the authentication flow to register FCM tokens with the server
4. Added a Notifications screen to display received notifications

## Server-Side Setup (Laravel Backend)

To complete the push notification implementation, you'll need to update your Laravel backend:

### 1. Install Required Packages

```bash
composer require kreait/firebase-php
composer require kreait/laravel-firebase
```

### 2. Configure Firebase

1. Download your Firebase service account JSON file from the Firebase Console
2. Store it securely in your Laravel project
3. Configure the Firebase connection in `config/services.php`:

```php
'firebase' => [
    'credential' => env('FIREBASE_CREDENTIALS', base_path('firebase-credentials.json')),
    'database_url' => env('FIREBASE_DATABASE_URL', 'https://your-project.firebaseio.com'),
],
```

### 3. Create API Endpoints

Create the following endpoints in your Laravel API:

#### Update Device Token Endpoint

```php
// routes/api.php
Route::middleware('auth:api')->post('/update-device-token', 'API\NotificationController@updateDeviceToken');

// app/Http/Controllers/API/NotificationController.php
public function updateDeviceToken(Request $request)
{
    $request->validate([
        'device_token' => 'required|string',
        'device_type' => 'required|in:android,ios',
    ]);

    try {
        // Update user's device token
        $user = auth()->user();
        $user->device_token = $request->device_token;
        $user->device_type = $request->device_type;
        $user->save();

        return response()->json([
            'status' => true,
            'message' => 'Device token updated successfully'
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => false,
            'message' => 'Failed to update device token: ' . $e->getMessage()
        ], 500);
    }
}
```

#### Notifications Endpoint

```php
// routes/api.php
Route::middleware('auth:api')->get('/notifications', 'API\NotificationController@getNotifications');
Route::middleware('auth:api')->post('/mark-notification-as-read', 'API\NotificationController@markAsRead');

// app/Http/Controllers/API/NotificationController.php
public function getNotifications()
{
    $user = auth()->user();
    $notifications = $user->notifications()->orderBy('created_at', 'desc')->get();
    
    return response()->json([
        'status' => true,
        'notifications' => $notifications
    ]);
}

public function markAsRead(Request $request)
{
    $request->validate([
        'notification_id' => 'required'
    ]);
    
    $user = auth()->user();
    $notification = $user->notifications()->find($request->notification_id);
    
    if ($notification) {
        $notification->read_at = now();
        $notification->save();
        
        return response()->json([
            'status' => true,
            'message' => 'Notification marked as read'
        ]);
    }
    
    return response()->json([
        'status' => false,
        'message' => 'Notification not found'
    ], 404);
}
```

### 4. Create Database Migrations

Add device token fields to the users table:

```php
// Create a new migration
php artisan make:migration add_device_token_to_users_table

// In the migration file
public function up()
{
    Schema::table('users', function (Blueprint $table) {
        $table->string('device_token')->nullable();
        $table->string('device_type')->nullable();
    });
}

public function down()
{
    Schema::table('users', function (Blueprint $table) {
        $table->dropColumn(['device_token', 'device_type']);
    });
}
```

Create notifications table:

```php
// Create a notifications migration if you don't have one
php artisan make:migration create_notifications_table

// In the migration file
public function up()
{
    Schema::create('notifications', function (Blueprint $table) {
        $table->uuid('id')->primary();
        $table->string('type');
        $table->morphs('notifiable');
        $table->text('data');
        $table->timestamp('read_at')->nullable();
        $table->timestamps();
    });
}
```

Run the migrations:

```bash
php artisan migrate
```

### 5. Create a Notification Service

```php
// app/Services/FirebaseNotificationService.php
<?php

namespace App\Services;

use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification as FirebaseNotification;
use Kreait\Laravel\Firebase\Facades\Firebase;

class FirebaseNotificationService
{
    public function sendNotification($token, $title, $body, $data = [])
    {
        try {
            $messaging = Firebase::messaging();
            
            // Create notification
            $notification = FirebaseNotification::create($title, $body);
            
            // Create message
            $message = CloudMessage::withTarget('token', $token)
                ->withNotification($notification)
                ->withData($data);
            
            // Send message
            $messaging->send($message);
            
            return true;
        } catch (\Exception $e) {
            \Log::error('Firebase notification error: ' . $e->getMessage());
            return false;
        }
    }
    
    public function sendTopicNotification($topic, $title, $body, $data = [])
    {
        try {
            $messaging = Firebase::messaging();
            
            // Create notification
            $notification = FirebaseNotification::create($title, $body);
            
            // Create message
            $message = CloudMessage::withTarget('topic', $topic)
                ->withNotification($notification)
                ->withData($data);
            
            // Send message
            $messaging->send($message);
            
            return true;
        } catch (\Exception $e) {
            \Log::error('Firebase topic notification error: ' . $e->getMessage());
            return false;
        }
    }
}
```

### 6. Usage Examples

#### Send Notification to a Specific User

```php
// In any controller
use App\Services\FirebaseNotificationService;

// Inject the service
public function __construct(FirebaseNotificationService $firebaseService)
{
    $this->firebaseService = $firebaseService;
}

// Send notification
public function sendCourseNotification($userId, $courseId, $courseTitle)
{
    $user = User::find($userId);
    
    if ($user && $user->device_token) {
        // Send push notification
        $this->firebaseService->sendNotification(
            $user->device_token,
            'New Course Available',
            "Check out our new course: $courseTitle",
            [
                'type' => 'course',
                'course_id' => $courseId
            ]
        );
        
        // Also store in database
        $user->notifications()->create([
            'title' => 'New Course Available',
            'body' => "Check out our new course: $courseTitle",
            'data' => json_encode([
                'type' => 'course',
                'course_id' => $courseId
            ])
        ]);
    }
}
```

#### Send Notification to All Users Subscribed to a Topic

```php
// Send to all students
$this->firebaseService->sendTopicNotification(
    'students',
    'Special Discount',
    'Get 50% off on all courses this week!',
    [
        'type' => 'promotion',
        'promotion_id' => $promotionId
    ]
);
```

## Firebase Console Setup

1. Create a Firebase project at [firebase.google.com](https://firebase.google.com)
2. Add Android and iOS apps to your project
3. Download the configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
4. Place these files in the appropriate locations in your Flutter project
5. Enable Cloud Messaging in the Firebase Console

## Testing Push Notifications

To test your push notifications, you can use the Firebase Console:

1. Go to Firebase Console > Your Project > Messaging
2. Create a new campaign
3. Select "Send test message" to send to specific devices
4. Use the registered FCM token for your test device
5. Customize the notification title, body, and data payload
6. Send the test message

## Troubleshooting

- **Notifications not showing**: Check if the app has notification permissions
- **FCM token not generated**: Verify Firebase initialization in the app
- **Notifications work in foreground but not background**: Check the background handler implementation
- **Server sending fails**: Verify your Firebase service account credentials

## Next Steps

- Implement notification categories and preferences
- Add rich media notifications (images, action buttons)
- Implement notification analytics 