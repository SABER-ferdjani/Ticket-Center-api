<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Enums\PostStatus;
use App\Enums\PostPriority;
use Illuminate\Database\Eloquent\SoftDeletes;  

class Ticket extends Model
{
    /** @use HasFactory<\Database\Factories\TicketFactory> */
    use HasFactory , SoftDeletes;
    // protected $connection = 'mysql';
    protected $table = 'tickets';
    public $timestamps = true;
    protected $dates = ['deleted_at' ,'completed_at'];
    //  protected $appends = [];
    // protected $with = [];
    protected $fillable = [
        'title',
        'reporter_id',
        'description',
        'status',
        'priority',
        'completed_at',
    ];
    protected $visible = [
        'id',
        'title',
        'reporter_id',
        'description',
        'status',
        'priority',
        'completed_at',
        'assigments', 
        'interventions' ,
        'reporter',
    ];

    // --- Add enum casts ---
    protected $casts = [
        'status' => PostStatus::class,
        'priority' => PostPriority::class,
        'completed_at' => 'datetime',
    ];

    public function reporter()
    {
        return $this->belongsTo(User::class, 'reporter_id');
    }

    public function assigments()
    {
        return $this->hasmany(Assignment::class, );
    }

    public function messages()
    {
        return $this->hasmany(Message::class, );
    }

    public function interventions()
    {
        return $this->hasmany(Intervention::class, );
    }

}
