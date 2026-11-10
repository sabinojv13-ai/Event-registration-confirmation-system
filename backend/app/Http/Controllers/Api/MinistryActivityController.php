<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MinistryActivity;
use Illuminate\Http\JsonResponse;

class MinistryActivityController extends Controller
{
    public function index(): JsonResponse
    {
        $activities = MinistryActivity::query()
            ->where('status', 'open')
            ->orderBy('starts_at')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $activities,
        ]);
    }

    public function show(MinistryActivity $ministryActivity): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => $ministryActivity,
        ]);
    }
}