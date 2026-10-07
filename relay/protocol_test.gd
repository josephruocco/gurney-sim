extends SceneTree
var sockets: Array[WebSocketPeer] = []
var failed := false
func check(ok: bool, message: String) -> void:
	if !ok:
		failed = true
		push_error(message)
func connect_socket() -> WebSocketPeer:
	var ws := WebSocketPeer.new()
	ws.connect_to_url("ws://127.0.0.1:9080")
	sockets.append(ws)
	for tick in 1500:
		ws.poll()
		if ws.get_ready_state() == WebSocketPeer.STATE_OPEN: return ws
		await process_frame
	check(false, "Connection timeout")
	return ws
func receive(ws: WebSocketPeer) -> Dictionary:
	for tick in 1500:
		for socket in sockets: socket.poll()
		if ws.get_available_packet_count() > 0: return bytes_to_var(ws.get_packet())
		await process_frame
	check(false, "Message timeout")
	return {}
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var host := await connect_socket()
	host.put_packet(var_to_bytes({"op": "create", "version": 1}))
	var welcome := await receive(host)
	check(welcome.get("welcome") == 1, "Creator must be host")
	var bad := await connect_socket()
	bad.put_packet(var_to_bytes({"op": "join", "version": 1, "code": "INVALID"}))
	check((await receive(bad)).has("error"), "Invalid code must fail")
	var guest := await connect_socket()
	guest.put_packet(var_to_bytes({"op": "join", "version": 1, "code": welcome.code}))
	check((await receive(guest)).get("welcome") == 2, "Guest must get peer 2")
	await receive(host)
	guest.put_packet(var_to_bytes({"target": 1, "from": 999, "data": PackedByteArray([42])}))
	var packet := await receive(host)
	check(packet.get("from") == 2, "Relay must assign sender, not trust client")
	check(packet.get("data") == PackedByteArray([42]), "Relay must preserve packet")
	host.put_packet(var_to_bytes({"lock": true}))
	var late := await connect_socket()
	late.put_packet(var_to_bytes({"op": "join", "version": 1, "code": welcome.code}))
	check((await receive(late)).has("error"), "Started room must reject join")
	host.close()
	check((await receive(guest)).get("error") == "Host left the room", "Host loss must close room")
	for ws in sockets: ws.close()
	print("Relay protocol tests passed" if !failed else "Relay protocol tests FAILED")
	quit(1 if failed else 0)
