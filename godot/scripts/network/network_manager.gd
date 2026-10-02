class_name NetworkManager
extends Node

signal peer_ready(peer_id: int)
signal connection_message(message: String)
signal peer_left(peer_id: int)
signal public_endpoint(message: String)

const PORT := 8910
const MAX_PLAYERS := 4
var active_port := PORT
var upnp: UPNP

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(func(): connection_message.emit("Connected as player %d" % multiplayer.get_unique_id()))
	multiplayer.connection_failed.connect(func(): connection_message.emit("Connection failed"))

func host(port := PORT, try_upnp := true) -> Error:
	var peer := ENetMultiplayerPeer.new()
	active_port = clampi(port, 1024, 65535)
	var error := peer.create_server(active_port, MAX_PLAYERS)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		connection_message.emit("Hosting on port %d" % active_port)
		peer_ready.emit(1)
		if try_upnp: _open_internet_port()
	return error

func join(address := "127.0.0.1", port := PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	active_port = clampi(port, 1024, 65535)
	var error := peer.create_client(address, active_port)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		connection_message.emit("Connecting to %s:%d" % [address, active_port])
	return error

func _open_internet_port() -> void:
	upnp = UPNP.new()
	var discovery := upnp.discover(2000, 2, "InternetGatewayDevice")
	if discovery != UPNP.UPNP_RESULT_SUCCESS or !upnp.get_gateway() or !upnp.get_gateway().is_valid_gateway():
		public_endpoint.emit("Internet: router did not provide UPnP — forward UDP %d manually" % active_port)
		return
	var mapping := upnp.add_port_mapping(active_port, active_port, "Gurney Simulator", "UDP", 0)
	if mapping == UPNP.UPNP_RESULT_SUCCESS:
		public_endpoint.emit("Internet invite: %s:%d" % [upnp.query_external_address(), active_port])
	else:
		public_endpoint.emit("Internet: forward UDP %d manually" % active_port)

func _exit_tree() -> void:
	if upnp and upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
		upnp.delete_port_mapping(active_port, "UDP")

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
