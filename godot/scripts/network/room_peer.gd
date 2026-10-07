extends MultiplayerPeerExtension

signal room_ready(code: String)
signal failed(message: String)
var socket := WebSocketPeer.new()
var status := MultiplayerPeer.CONNECTION_DISCONNECTED
var own_id := 0
var target := 0
var channel := 0
var mode := MultiplayerPeer.TRANSFER_MODE_RELIABLE
var refusing := false
var queue: Array[Dictionary] = []
var last_sender := 0
var hello: Dictionary
var sent_hello := false
var started := 0

func connect_room(url: String, code: String) -> Error:
	hello = {"op": "create" if code.is_empty() else "join", "code": code, "version": 1}
	var error := socket.connect_to_url(url)
	if error == OK:
		status = MultiplayerPeer.CONNECTION_CONNECTING
		started = Time.get_ticks_msec()
	return error

func _poll() -> void:
	socket.poll()
	if status == MultiplayerPeer.CONNECTION_CONNECTING and Time.get_ticks_msec() - started > 15000:
		failed.emit("Relay connection timed out")
		_close()
		return
	if socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		if status != MultiplayerPeer.CONNECTION_DISCONNECTED: failed.emit("Relay disconnected")
		status = MultiplayerPeer.CONNECTION_DISCONNECTED
		return
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN: return
	if !sent_hello:
		socket.put_packet(var_to_bytes(hello))
		sent_hello = true
	while socket.get_available_packet_count() > 0:
		var msg = bytes_to_var(socket.get_packet())
		if !msg is Dictionary: continue
		if msg.has("error"):
			failed.emit(str(msg.error))
			_close()
			return
		if msg.has("welcome"):
			own_id = int(msg.welcome)
			status = MultiplayerPeer.CONNECTION_CONNECTED
			room_ready.emit(str(msg.code))
			for id in msg.peers: peer_connected.emit(int(id))
		elif msg.has("joined"): peer_connected.emit(int(msg.joined))
		elif msg.has("left"): peer_disconnected.emit(int(msg.left))
		elif msg.has("data"): queue.append(msg)

func _get_packet_script() -> PackedByteArray:
	var packet: Dictionary = queue.pop_front()
	last_sender = int(packet.from)
	return packet.data
func _put_packet_script(data: PackedByteArray) -> Error:
	return socket.put_packet(var_to_bytes({"target": target, "channel": channel, "mode": mode, "data": data}))
func _get_available_packet_count() -> int: return queue.size()
func _get_packet_peer() -> int: return int(queue[0].from) if !queue.is_empty() else last_sender
func _get_packet_channel() -> int: return int(queue[0].channel) if !queue.is_empty() else 0
func _get_packet_mode() -> MultiplayerPeer.TransferMode: return int(queue[0].mode) as MultiplayerPeer.TransferMode if !queue.is_empty() else mode
func _get_max_packet_size() -> int: return 60000
func _get_unique_id() -> int: return own_id
func _get_connection_status() -> MultiplayerPeer.ConnectionStatus: return status
func _is_server() -> bool: return own_id == 1
func _is_server_relay_supported() -> bool: return true
func _set_target_peer(value: int) -> void: target = value
func _set_transfer_channel(value: int) -> void: channel = value
func _get_transfer_channel() -> int: return channel
func _set_transfer_mode(value: MultiplayerPeer.TransferMode) -> void: mode = value
func _get_transfer_mode() -> MultiplayerPeer.TransferMode: return mode
func _is_refusing_new_connections() -> bool: return refusing
func _set_refuse_new_connections(value: bool) -> void:
	refusing = value
	if own_id == 1: socket.put_packet(var_to_bytes({"lock": value}))
func _disconnect_peer(_peer: int, _force: bool) -> void: pass
func _close() -> void:
	socket.close()
	status = MultiplayerPeer.CONNECTION_DISCONNECTED
	queue.clear()
