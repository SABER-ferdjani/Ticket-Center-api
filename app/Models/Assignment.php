<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Assignment extends Model
{
    /** @use HasFactory<\Database\Factories\AssignmentFactory> */
    use HasFactory;

    // protected $connection = 'mysql';
    protected $table = 'assignments';
    public $timestamps = true;
    protected $dates = ['deleted_at'];
    //  protected $appends = [];
    // protected $with = ['ticket']; 

    protected $fillable = [
        'ticket_id', 
        'leader_id',
        'dispatcher_id',
    ];

    // protected $visible = [];

   public function technicians()
    {
        return $this->belongsToMany(User::class, 'assignment_user', 'assignment_id', 'user_id');
    }

    public function ticket()
    {
        return $this->belongsTo(Ticket::class, 'ticket_id');
    }

    public function leader()
    {
        return $this->belongsTo(User::class, 'leader_id');
    }
    public function dispatcher()
    {
        return $this->belongsTo(User::class, 'dispatcher_id');
    }
}
