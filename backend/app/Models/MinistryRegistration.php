<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MinistryRegistration extends Model
{
    use HasFactory;

    protected $fillable = [
        'ministry_activity_id',
        'member_name',
        'member_email',
        'ministry_role',
        'status',
        'confirmed_at',
        'cancelled_at',
        'attended_at',
    ];

    protected function casts(): array
    {
        return [
            'confirmed_at' => 'datetime',
            'cancelled_at' => 'datetime',
            'attended_at' => 'datetime',
            'reminder_sent_at' => 'datetime',
        ];
    }

    public function ministryActivity(): BelongsTo
    {
        return $this->belongsTo(MinistryActivity::class);
    }
}
