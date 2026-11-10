<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\MinistryActivityController;
use App\Http\Controllers\Api\MinistryRegistrationController;

Route::get('/activities', [
    MinistryActivityController::class,
    'index',
]);

Route::get('/activities/{ministryActivity}', [
    MinistryActivityController::class,
    'show',
]);

Route::post('/activities/{ministryActivity}/registrations', [
    MinistryRegistrationController::class,
    'store',
]);

Route::post(
    '/activities/{ministryActivity}/registrations/{registration}/cancel',
    [MinistryRegistrationController::class, 'cancel']
);

Route::post(
    '/activities/{ministryActivity}/registrations/{registration}/attendance',
    [MinistryRegistrationController::class, 'markAttendance']
);

Route::get(
    '/activities/{ministryActivity}/no-shows',
    [MinistryRegistrationController::class, 'noShowReport']
);