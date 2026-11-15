<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrdemServico extends Model
{
    protected $table = 'ordens_servico';

    protected $fillable = ['number', 'aparelho_id', 'created_by', 'assigned_to', 'problem', 'diagnosis', 'status', 'price', 'notes'];

    protected function casts(): array
    {
        return ['price' => 'decimal:2'];
    }

    public function aparelho()
    {
        return $this->belongsTo(Aparelho::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function assignedUser()
    {
        return $this->belongsTo(User::class, 'assigned_to');
    }

    public function history()
    {
        return $this->hasMany(RepairHistory::class)->orderBy('id');
    }
}
