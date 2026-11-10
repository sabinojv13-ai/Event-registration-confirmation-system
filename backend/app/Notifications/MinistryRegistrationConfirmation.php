<?php

namespace App\Notifications;

use App\Models\MinistryRegistration;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class MinistryRegistrationConfirmation extends Notification
{
    use Queueable;

    public function __construct(
        public MinistryRegistration $registration
    ) {
    }

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $this->registration->loadMissing('ministryActivity');

        $isConfirmed = $this->registration->status === 'confirmed';

        $subject = $isConfirmed
            ? 'Ministry Activity Registration Confirmed'
            : 'Ministry Activity Waiting List';

        $message = $isConfirmed
            ? 'Your registration has been confirmed. We look forward to seeing you at the ministry activity.'
            : 'This activity is currently full. You have been placed on the waiting list. We will update you if a place becomes available.';

        return (new MailMessage)
            ->subject($subject)
            ->greeting('Hello ' . $this->registration->member_name . '!')
            ->line($message)
            ->line(
                'Activity: ' .
                ($this->registration->ministryActivity?->title ?? 'Ministry Activity')
            )
            ->line('Ministry role: ' . $this->registration->ministry_role)
            ->line('Thank you for participating in our parish ministry.');
    }

    public function toArray(object $notifiable): array
    {
        return [
            'registration_id' => $this->registration->id,
            'activity_id' => $this->registration->ministry_activity_id,
            'status' => $this->registration->status,
        ];
    }
}
