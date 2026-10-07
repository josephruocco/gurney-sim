extends SceneTree

const MAX_ROOMS := 100
const MAX_CLIENTS := 400
var server := TCPServer.new()
var clients: Dictionary = {}
var rooms: Dictionary = {}
var serial := 0

func _initialize() -> void:
	var port := int(OS.get_environment("PORT")) if OS.has_environment("PORT") else 9080
	var error := server.listen(port, "0.0.0.0")
	if error != OK:
		push_error("Cannot listen: %s" % error)
		quit(1)
	print("RELAY listening ", port)

func send_to(id: int, data: Dictionary) -> void:
	if clients.has(id): clients[id].ws.put_packet(var_to_bytes(data))

func _process(_delta: float) -> bool:
	while server.is_connection_available():
		var tcp := server.take_connection()
		if clients.size() >= MAX_CLIENTS:
			tcp.disconnect_from_host()
			continue
		var ws := WebSocketPeer.new()
		ws.inbound_buffer_size = 262144
		ws.outbound_buffer_size = 262144
		ws.accept_stream(tcp)
		serial += 1
		clients[serial] = {"ws": ws, "room": "", "peer": 0, "born": Time.get_ticks_msec(), "count": 0, "second": 0}
	for id in clients.keys():
		if !clients.has(id): continue
		var c: Dictionary = clients[id]
		var ws: WebSocketPeer = c.ws
		ws.poll()
		if ws.get_ready_state() == WebSocketPeer.STATE_CLOSED:
			remove_client(id)
			continue
		if c.room == "" and Time.get_ticks_msec() - c.born > 15000:
			ws.close(1008, "Handshake timeout")
		while ws.get_available_packet_count() > 0 and clients.has(id):
			var packet := ws.get_packet()
			var second := Time.get_ticks_msec() / 1000
			if c.second != second: c.second = second; c.count = 0
			c.count += 1
			if packet.size() > 65536 or c.count > 300:
				ws.close(1008, "Rate or size limit")
				break
			var message = bytes_to_var(packet)
			if message is Dictionary: handle(id, message)
	return false

func handle(id: int, msg: Dictionary) -> void:
	var c: Dictionary = clients[id]
	if c.room == "":
		if msg.get("version") != 1: send_to(id, {"error": "Update required"}); return
		var code: String = str(msg.get("code", "")).to_upper()
		if msg.get("op") == "create":
			if rooms.size() >= MAX_ROOMS: send_to(id, {"error": "Relay full"}); return
			code = Crypto.new().generate_random_bytes(4).hex_encode().to_upper()
			while rooms.has(code): code = Crypto.new().generate_random_bytes(4).hex_encode().to_upper()
			rooms[code] = {"members": [], "next": 2, "locked": false}
		elif msg.get("op") != "join" or !rooms.has(code):
			send_to(id, {"error": "Room not found"}); return
		var room: Dictionary = rooms[code]
		if room.members.size() >= 4 or room.locked:
			send_to(id, {"error": "Room full or already playing"}); return
		c.room = code
		c.peer = 1 if room.members.is_empty() else room.next
		if c.peer != 1: room.next += 1
		var others: Array = []
		for member in room.members: others.append(clients[member].peer)
		room.members.append(id)
		send_to(id, {"welcome": c.peer, "code": code, "peers": others})
		for member in room.members:
			if member != id: send_to(member, {"joined": c.peer})
		return
	var room: Dictionary = rooms[c.room]
	if msg.has("lock") and c.peer == 1:
		room.locked = bool(msg.lock)
		return
	if !msg.get("data") is PackedByteArray: return
	var target := int(msg.get("target", 0))
	# Only host broadcasts game state; clients address the authoritative host.
	if c.peer != 1 and target != 1: return
	for member in room.members:
		var peer_id: int = clients[member].peer
		if member != id and (target == 0 or target == peer_id or (target < 0 and peer_id != -target)):
			send_to(member, {"from": c.peer, "channel": int(msg.get("channel", 0)), "mode": int(msg.get("mode", 2)), "data": msg.data})

func remove_client(id: int) -> void:
	var c: Dictionary = clients[id]
	clients.erase(id)
	if !rooms.has(c.room): return
	var room: Dictionary = rooms[c.room]
	room.members.erase(id)
	if c.peer == 1:
		for member in room.members:
			send_to(member, {"error": "Host left the room"})
			clients[member].room = ""
			clients[member].born = Time.get_ticks_msec() - 14000
		rooms.erase(c.room)
	else:
		for member in room.members: send_to(member, {"left": c.peer})
