<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\Ticket;

class Intervention extends Model
{
    /** @use HasFactory<\Database\Factories\InterventionsFactory> */
    use HasFactory;

    // protected $connection = 'mysql';
    protected $table = 'interventions';
    public $timestamps = true;
    protected $dates = ['deleted_at','appointment'];
    //  protected $appends = [];
    // protected $with = [];
    protected $fillable = ['note','appointment','ticket_id'];
    protected $visible = ['note','appointment','id'];

    public function ticket()
    {
        return $this->belongsTo(Ticket::class, 'ticket_id');
    }
     
}
