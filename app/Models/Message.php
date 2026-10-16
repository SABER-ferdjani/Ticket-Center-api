<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    use HasFactory;

    // protected $connection = 'mysql';
    protected $table      = 'messages';
    public    $timestamps = true;

    protected $fillable = [
        'ticket_id',
        'sender_id',   // nullable for system messages
        'message',
        'type',        // 'chat' | 'system'
    ];

    protected $visible = [
        'id',
        'ticket_id',
        'sender_id',
        'sender_name', // appended below
        'message',
        'type',
        'created_at',
        'sender',
    ];

    // Default type to 'chat' so existing code doesn't need to change
    protected $attributes = [
        'type' => 'chat',
    ];

    // ── Relations ──────────────────────────────────────────────
    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    public function ticket()
    {
        return $this->belongsTo(Ticket::class, 'ticket_id');
    }
}