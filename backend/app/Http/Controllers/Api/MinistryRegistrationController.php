<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MinistryActivity;
use App\Models\MinistryRegistration;
use App\Notifications\MinistryRegistrationConfirmation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;
use Illuminate\Validation\ValidationException;

class MinistryRegistrationController extends Controller
{
    public function store(
        Request $request,
        MinistryActivity $ministryActivity
    ): JsonResponse {
        $validated = $request->validate([
            'member_name' => ['required', 'string', 'max:255'],
            'member_email' => ['required', 'email', 'max:255'],
            'ministry_role' => [
                'required',
                'in:Choir,Lectors,Commentators,Altar Servers',
            ],
        ]);

        $validated['member_email'] = strtolower(
            trim($validated['member_email'])
        );

        $registration = DB::transaction(function () use (
            $validated,
            $ministryActivity
        ) {
            $activity = MinistryActivity::query()
                ->whereKey($ministryActivity->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($activity->status !== 'open') {
                throw ValidationException::withMessages([
                    'activity' => [
                        'This activity is not accepting registrations.',
                    ],
                ]);
            }

            $existing = MinistryRegistration::query()
                ->where('ministry_activity_id', $activity->id)
                ->whereRaw('LOWER(member_email) = ?', [
                    $validated['member_email'],
                ])
                ->whereIn('status', ['confirmed', 'waitlisted'])
                ->exists();

            if ($existing) {
                throw ValidationException::withMessages([
                    'member_email' => [
                        'This member is already registered for this activity.',
                    ],
                ]);
            }

            $confirmed = MinistryRegistration::query()
                ->where('ministry_activity_id', $activity->id)
                ->where('status', 'confirmed')
                ->count();

            $status = $confirmed < $activity->capacity
                ? 'confirmed'
                : 'waitlisted';

            $registration = MinistryRegistration::create([
                'ministry_activity_id' => $activity->id,
                'member_name' => $validated['member_name'],
                'member_email' => $validated['member_email'],
                'ministry_role' => $validated['ministry_role'],
                'status' => $status,
                'confirmed_at' => $status === 'confirmed' ? now() : null,
            ]);

            $activity->update([
                'confirmed_count' => $confirmed
                    + ($status === 'confirmed' ? 1 : 0),
            ]);

            return $registration;
        });

        Log::info('ministry_registration.created', [
            'registration_id' => $registration->id,
            'activity_id' => $registration->ministry_activity_id,
            'status' => $registration->status,
        ]);

        $this->sendRegistrationNotification($registration);

        return response()->json([
            'success' => true,
            'message' => $registration->status === 'confirmed'
                ? 'Registration confirmed.'
                : 'Activity is full. Member added to the waiting list.',
            'data' => $registration->fresh(),
        ], 201);
    }

    public function cancel(
        MinistryActivity $ministryActivity,
        MinistryRegistration $registration
    ): JsonResponse {
        $result = DB::transaction(function () use (
            $ministryActivity,
            $registration
        ) {
            $activity = MinistryActivity::query()
                ->whereKey($ministryActivity->id)
                ->lockForUpdate()
                ->firstOrFail();

            $current = MinistryRegistration::query()
                ->whereKey($registration->id)
                ->where('ministry_activity_id', $activity->id)
                ->lockForUpdate()
                ->firstOrFail();

            if (!in_array($current->status, ['confirmed', 'waitlisted'], true)) {
                throw ValidationException::withMessages([
                    'registration' => [
                        'This registration cannot be cancelled.',
                    ],
                ]);
            }

            $wasConfirmed = $current->status === 'confirmed';

            $current->update([
                'status' => 'cancelled',
                'cancelled_at' => now(),
            ]);

            $promoted = null;

            if ($wasConfirmed) {
                $promoted = MinistryRegistration::query()
                    ->where('ministry_activity_id', $activity->id)
                    ->where('status', 'waitlisted')
                    ->orderBy('created_at')
                    ->orderBy('id')
                    ->lockForUpdate()
                    ->first();

                if ($promoted) {
                    $promoted->update([
                        'status' => 'confirmed',
                        'confirmed_at' => now(),
                    ]);
                }
            }

            $confirmedCount = MinistryRegistration::query()
                ->where('ministry_activity_id', $activity->id)
                ->where('status', 'confirmed')
                ->count();

            $activity->update([
                'confirmed_count' => $confirmedCount,
            ]);

            return [
                'cancelled' => $current->fresh(),
                'promoted' => $promoted?->fresh(),
            ];
        });

        Log::info('ministry_registration.cancelled', [
            'registration_id' => $result['cancelled']->id,
            'activity_id' => $ministryActivity->id,
            'promoted_registration_id' => $result['promoted']?->id,
        ]);

        if ($result['promoted']) {
            $this->sendRegistrationNotification($result['promoted']);
        }

        return response()->json([
            'success' => true,
            'message' => $result['promoted']
                ? 'Registration cancelled. The next waiting-list member has been promoted.'
                : 'Registration cancelled successfully.',
            'data' => [
                'cancelled_registration' => $result['cancelled'],
                'promoted_registration' => $result['promoted'],
            ],
        ]);
    }

    public function markAttendance(
        Request $request,
        MinistryActivity $ministryActivity,
        MinistryRegistration $registration
    ): JsonResponse {
        $validated = $request->validate([
            'attended' => ['required', 'boolean'],
        ]);

        if ($registration->ministry_activity_id !== $ministryActivity->id) {
            return response()->json([
                'success' => false,
                'message' => 'Registration does not belong to this activity.',
            ], 404);
        }

        if ($registration->status !== 'confirmed') {
            return response()->json([
                'success' => false,
                'message' => 'Only confirmed registrations can have attendance recorded.',
            ], 422);
        }

        $registration->update([
            'attended_at' => $validated['attended']
                ? ($registration->attended_at ?? now())
                : null,
        ]);

        Log::info('ministry_registration.attendance_recorded', [
            'registration_id' => $registration->id,
            'activity_id' => $ministryActivity->id,
            'attended' => (bool) $validated['attended'],
        ]);

        return response()->json([
            'success' => true,
            'message' => $validated['attended']
                ? 'Attendance recorded successfully.'
                : 'Attendance mark cleared successfully.',
            'data' => $registration->fresh(),
        ]);
    }

    
public function noShowReport(
    MinistryActivity $ministryActivity
): JsonResponse {
    if ($ministryActivity->starts_at >= now()) {
        return response()->json([
            'success' => false,
            'message' => 'The no-show report is available only after the activity has started.',
            'data' => [],
        ], 422);
    }

    $registrations = MinistryRegistration::query()
        ->where('ministry_activity_id', $ministryActivity->id)
        ->where('status', 'confirmed')
        ->whereNull('attended_at')
        ->orderBy('member_name')
        ->get([
            'id',
            'ministry_activity_id',
            'member_name',
            'member_email',
            'ministry_role',
            'status',
            'attended_at',
        ]);

    Log::info('ministry_activity.no_show_report_generated', [
        'activity_id' => $ministryActivity->id,
        'no_show_count' => $registrations->count(),
    ]);

    return response()->json([
        'success' => true,
        'message' => 'No-show report generated successfully.',
        'data' => [
            'activity' => [
                'id' => $ministryActivity->id,
                'title' => $ministryActivity->title,
                'starts_at' => $ministryActivity->starts_at,
            ],
            'no_show_count' => $registrations->count(),
            'registrations' => $registrations,
        ],
    ]);
}

    private function sendRegistrationNotification(
        MinistryRegistration $registration
    ): void {
        $registration->load('ministryActivity');

        $maxAttempts = 3;

        $simulateTransient = filter_var(
            env('MINISTRY_SIMULATE_TRANSIENT_FAILURE', false),
            FILTER_VALIDATE_BOOLEAN
        );

        $simulatePermanent = filter_var(
            env('MINISTRY_SIMULATE_PERMANENT_FAILURE', false),
            FILTER_VALIDATE_BOOLEAN
        );

        for ($attempt = 1; $attempt <= $maxAttempts; $attempt++) {
            try {
                if ($simulateTransient && $attempt === 1) {
                    throw new \RuntimeException(
                        'Simulated temporary notification failure.'
                    );
                }

                if ($simulatePermanent) {
                    throw new \RuntimeException(
                        'Simulated permanent notification failure.'
                    );
                }

                Notification::route('mail', $registration->member_email)
                    ->notify(
                        new MinistryRegistrationConfirmation($registration)
                    );

                Log::info('ministry_registration.notification_processed', [
                    'registration_id' => $registration->id,
                    'attempt' => $attempt,
                ]);

                if ($attempt > 1) {
                    Log::warning(
                        'ministry_registration.notification_recovered',
                        [
                            'registration_id' => $registration->id,
                            'successful_attempt' => $attempt,
                        ]
                    );
                }

                return;
            } catch (\Throwable $exception) {
                $permanent = $simulatePermanent;
                $lastAttempt = $attempt === $maxAttempts;

                Log::warning(
                    'ministry_registration.notification_attempt_failed',
                    [
                        'registration_id' => $registration->id,
                        'attempt' => $attempt,
                        'error' => $exception->getMessage(),
                    ]
                );

                if ($permanent || $lastAttempt) {
                    Log::error(
                        'ministry_registration.notification_requires_human_action',
                        [
                            'registration_id' => $registration->id,
                            'activity_id' => $registration->ministry_activity_id,
                            'attempts' => $attempt,
                            'action_required' => true,
                            'error' => $exception->getMessage(),
                        ]
                    );

                    return;
                }

                usleep(250000 * $attempt);
            }
        }
    }
}
