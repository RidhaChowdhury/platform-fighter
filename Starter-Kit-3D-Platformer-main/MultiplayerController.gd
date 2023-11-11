extends Node2D


@export var address = "127.0.0.1"
@export var port = 8910
var peer
var compression_type = ENetConnection.COMPRESS_RANGE_CODER

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)


# Called on servers and clients
func peer_connected(id):
	print("Player Connected " + str(id))
# Called on servers and clients
	
func peer_disconnected(id):
	print("Player Disconnected " + str(id))

# Called on clients	
func connected_to_server():
	print("Connected to Server!")
	send_player_information.rpc_id(1, $LineEdit.text, multiplayer.get_unique_id())

# Called on clients	
func connection_failed():
	print("Connection Failed!")
	
@rpc("any_peer")
func send_player_information(name, id):
	if !GameManager.players.has(id):
		GameManager.players[id] = {
			"name": name,
			"id": id,
			"score": 0
		}
		
		if multiplayer.is_server():
			for i in GameManager.players:
				send_player_information.rpc(GameManager.players[i].name, i)

@rpc("any_peer", "call_local")
func start_game():
	var scene = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_host_pressed():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 2)
	if error != OK:
		print("Cannot host: " + error)
		return
		
	peer.get_host().compress(compression_type)
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for players!")
	send_player_information($LineEdit.text, multiplayer.get_unique_id())


func _on_join_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	peer.get_host().compress(compression_type)
	multiplayer.set_multiplayer_peer(peer)
	
func _on_start_pressed():
	start_game.rpc()
