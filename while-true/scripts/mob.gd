extends Area2D

@export var move_speed: float = 180.0

var player: Node2D = null
var timer := 3.35

func _ready():
	connect("body_entered", _on_body_entered)

	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]

func _process(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * move_speed * delta
	
	timer -= delta
	if timer <= 0:
		self.queue_free()

func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.respawn()
		self.queue_free()
