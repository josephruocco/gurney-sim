class_name NetworkManager
extends Node

signal peer_ready(peer_id: int)
signal connection_message(message: String)
signal peer_left(peer_id: int)

const PORT := 8910
const MAX_PLAYERS := 4

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(func(): connection_message.emit("Connected as player %d" % multiplayer.get_unique_id()))
	multiplayer.connection_failed.connect(func(): connection_message.emit("Connection failed"))

func host() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_PLAYERS)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		connection_message.emit("Hosting on port %d" % PORT)
		peer_ready.emit(1)
	return error

func join(address := "127.0.0.1") -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, PORT)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		connection_message.emit("Connecting to %s:%d" % [address, PORT])
	return error

func offline() -> void:
	var peer := OfflineMultiplayerPeer.new()
	multiplayer.multiplayer_peer = peer
	peer_ready.emit(1)
	connection_message.emit("Solo prototype")

func _on_peer_connected(id: int) -> void:
	connection_message.emit("Player %d joined" % id)
	if multiplayer.is_server():
		peer_ready.emit(id)

func _on_peer_disconnected(id: int) -> void:
	connection_message.emit("Player %d left" % id)
	peer_left.emit(id)
