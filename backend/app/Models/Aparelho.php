<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Aparelho extends Model
{
    protected $fillable = ['cliente_id', 'brand', 'model', 'imei', 'notes'];

    public function cliente()
    {
        return $this->belongsTo(Cliente::class);
    }

    public function ordens()
    {
        return $this->hasMany(OrdemServico::class);
    }
}
