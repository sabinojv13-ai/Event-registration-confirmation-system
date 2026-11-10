<?php

namespace App\Notifications;

use App\Models\MinistryRegistration;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class MinistryActivityReminder extends Notification
{
    use Queueable;

    public function __construct(
        public MinistryRegistration $registration
    ) {
        //
    }

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $activity = $this->registration->ministryActivity;

        return (new MailMessage)
            ->subject('Reminder: Upcoming Ministry Activity')
            ->greeting(
                'Hello ' . $this->registration->member_name . '!'
            )
            ->line(
                'This is a friendly reminder that you are registered for an upcoming ministry activity.'
            )
            ->line(
                'Activity: ' . ($activity?->title ?? 'Ministry Activity')
            )
            ->line(
                'Ministry role: ' . $this->registration->ministry_role
            )
            ->line(
                'Please check your activity schedule and arrive on time.'
            )
            ->line(
                'Thank you for serving our parish community.'
            );
    }

    public function toArray(object $notifiable): array
    {
        return [
            'registration_id' => $this->registration->id,
            'activity_id' => $this->registration->ministry_activity_id,
            'type' => 'activity_reminder',
        ];
    }
}
