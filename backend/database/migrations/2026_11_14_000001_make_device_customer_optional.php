<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('aparelhos', function (Blueprint $table) {
            $table->unsignedBigInteger('cliente_id')->nullable()->change();
        });
    }

    public function down(): void
    {
        if (DB::table('aparelhos')->whereNull('cliente_id')->exists()) {
            throw new RuntimeException('Link every device to a customer before rolling back this migration.');
        }

        Schema::table('aparelhos', function (Blueprint $table) {
            $table->unsignedBigInteger('cliente_id')->nullable(false)->change();
        });
    }
};
