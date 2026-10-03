GURNEY SIMULATOR — TWO MAC WI-FI TEST

This is a development test package, not a signed App Store release.
Includes a universal Godot runtime for Intel and Apple Silicon Macs.

1. Send the ZIP using AirDrop or file sharing. Unzip on both Macs.
2. Open Start.command inside Gurney-Simulator. Keep the folder together.
   If macOS blocks it, use System Settings > Privacy & Security to review
   the block and allow this package only if you trust its source.
3. Enter your name BEFORE clicking Host or Join localhost.
4. On the hosting Mac, leave 127.0.0.1:8910 in the address field and click Host ONCE.
5. Find the host's Wi-Fi IP in System Settings > Wi-Fi > Details > TCP/IP.
6. On the second Mac, replace 127.0.0.1:8910 with HOST-IP:8910
   (example: 192.168.1.25:8910), then click Join localhost ONCE.
   The current button label says localhost, but uses the entered address.
7. Confirm two names in the roster, then click Ready up on BOTH Macs.
8. WASD moves. E grabs/releases the gurney. Space brakes. Host uses R after a loss.

Verify: both avatars appear; walking on either Mac appears on the other;
both can grab; the gurney and patient move together; results match.

No router port forwarding is needed for this same-Wi-Fi test. The internet
UPnP message can be ignored. Allow incoming connections for Godot if macOS
asks. Guest Wi-Fi may isolate devices: use the same normal network.
Do not click Host or Join repeatedly or switch Solo/Host mid-session:
close and reopen the game before changing roles.

If connection fails, check the host IP, Wi-Fi isolation, and macOS firewall.
This package has been checked locally; a second physical Mac still needs testing.
