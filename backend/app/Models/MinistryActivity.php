<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MinistryActivity extends Model
{
    protected $fillable = [
        'title',
        'description',
        'ministry_role',
        'starts_at',
        'capacity',
        'confirmed_count',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'starts_at' => 'datetime',
            'capacity' => 'integer',
            'confirmed_count' => 'integer',
        ];
    }

    public function registrations(): HasMany
    {
        return $this->hasMany(MinistryRegistration::class);
    }
}