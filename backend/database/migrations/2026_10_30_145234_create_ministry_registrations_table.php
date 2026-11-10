<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    
public function up(): void
{
    Schema::create('ministry_registrations', function (Blueprint $table) {
        $table->id();
        $table->foreignId('ministry_activity_id')
            ->constrained('ministry_activities')
            ->cascadeOnDelete();

        $table->string('member_name');
        $table->string('member_email');
        $table->string('ministry_role');
        $table->string('status')->default('confirmed');
        $table->dateTime('confirmed_at')->nullable();
        $table->dateTime('cancelled_at')->nullable();
        $table->dateTime('attended_at')->nullable();
        $table->timestamps();

        $table->unique(
            ['ministry_activity_id', 'member_email'],
            'activity_member_email_unique'
        );
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ministry_registrations');
    }
};
