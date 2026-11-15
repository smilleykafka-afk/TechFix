<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('role')->default('employee');
        });
        Schema::create('clientes', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->nullable();
            $table->string('phone', 30);
            $table->text('address')->nullable();
            $table->timestamps();
        });
        Schema::create('aparelhos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('cliente_id')->constrained('clientes')->restrictOnDelete();
            $table->string('brand');
            $table->string('model');
            $table->string('imei', 30)->nullable()->unique();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
        Schema::create('ordens_servico', function (Blueprint $table) {
            $table->id();
            $table->string('number')->unique();
            $table->foreignId('aparelho_id')->constrained('aparelhos')->restrictOnDelete();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('assigned_to')->nullable()->constrained('users')->nullOnDelete();
            $table->text('problem');
            $table->text('diagnosis')->nullable();
            $table->string('status')->default('received')->index();
            $table->decimal('price', 10, 2)->default(0);
            $table->text('notes')->nullable();
            $table->timestamps();
        });
        Schema::create('repair_history', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ordem_servico_id')->constrained('ordens_servico')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('status');
            $table->timestamps();
        });
        Schema::create('parts', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('sku')->unique();
            $table->unsignedInteger('quantity')->default(0);
            $table->decimal('price', 10, 2)->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        foreach (['parts', 'repair_history', 'ordens_servico', 'aparelhos', 'clientes'] as $table) {
            Schema::dropIfExists($table);
        }
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('role');
        });
    }
};
