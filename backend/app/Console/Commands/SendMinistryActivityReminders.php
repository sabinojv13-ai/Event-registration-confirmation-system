<?php

namespace App\Console\Commands;

use App\Models\MinistryRegistration;
use App\Notifications\MinistryActivityReminder;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;

class SendMinistryActivityReminders extends Command
{
    protected $signature = 'ministry:send-reminders';

    protected $description = 'Send reminders for upcoming ministry activities';

    public function handle(): int
    {
        $now = now();

        // Find confirmed registrations for activities starting
        // between 23 and 25 hours from now.
        $registrations = MinistryRegistration::with('ministryActivity')
            ->where('status', 'confirmed')
            ->whereNull('reminder_sent_at')
            ->whereHas('ministryActivity', function ($query) use ($now) {
                $query->whereBetween('starts_at', [
                    $now->copy()->addHours(23),
                    $now->copy()->addHours(25),
                ]);
            })
            ->get();

        $sent = 0;
        $failed = 0;

        foreach ($registrations as $registration) {
            try {
                Notification::route(
                    'mail',
                    $registration->member_email
                )->notify(
                    new MinistryActivityReminder($registration)
                );

                $registration->forceFill([
                    'reminder_sent_at' => now(),
                ])->save();

                $sent++;

                Log::info('Ministry activity reminder sent', [
                    'registration_id' => $registration->id,
                    'activity_id' => $registration->ministry_activity_id,
                ]);
            } catch (\Throwable $exception) {
                $failed++;

                Log::error('Ministry activity reminder failed', [
                    'registration_id' => $registration->id,
                    'activity_id' => $registration->ministry_activity_id,
                    'error' => $exception->getMessage(),
                    'requires_human_action' => true,
                ]);
            }
        }

        $this->info("Reminders sent: {$sent}");
        $this->info("Reminders failed: {$failed}");

        return $failed > 0 ? self::FAILURE : self::SUCCESS;
    }
}
