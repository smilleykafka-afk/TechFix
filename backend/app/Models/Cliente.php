<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Cliente extends Model
{
    protected $fillable = ['name', 'email', 'phone', 'address'];

    public function aparelhos()
    {
        return $this->hasMany(Aparelho::class);
    }
}
