#!/bin/bash
# Script to launch MusicBee with a VPN tunnel, to bypass Imgur rate limiting for DiscordBee

# Change these to match your environment
USERNAME=your_username
WINEPREFIX="/home/your_username/.wine"
MUSICBEE="C:/users/your_username/AppData/Roaming/Microsoft/Windows/Start\ Menu/Programs/MusicBee/MusicBee.lnk"
IPC_BRIDGE="C:/path/to/winediscordipcbridge.exe"
OPENVPN_CONF="/path/to/some_openvpn_configuration.ovpn"



# Elevate this script to sudo when needed (requires an exception in etc/sudoers)
if [ "`id -u`" -ne 0 ]; then
    echo "Switching from `id -un` to root"
    exec sudo "$0"
fi

# Some stuff that we can grab automatically on most systems
USER_ID=$(id -u $USERNAME)
NETWORK_DEVICE=$(ip route | grep '^default' | awk '{print $5}')
HOME="/home/$USERNAME"

# Create a network namespace for MusicBee
sudo ip netns add musicbee_ns

# I don't know how any of this works, or if all of it is necessary, but it works somehow
sudo ip link add veth-musicbee type veth peer name veth-main
sudo ip link add name br-musicbee type bridge
sudo ip link set br-musicbee up
sudo ip link set veth-main master br-musicbee
sudo ip link set veth-main up
sudo ip link set veth-musicbee netns musicbee_ns
sudo ip netns exec musicbee_ns ip link set veth-musicbee up

# Route IP addresses or something
sudo ip addr add 10.200.1.254/24 dev br-musicbee
sudo ip netns exec musicbee_ns ip addr add 10.200.1.1/24 dev veth-musicbee
sudo ip netns exec musicbee_ns ip route add default via 10.200.1.254
sudo iptables -t nat -A POSTROUTING -s 10.200.1.0/24 -o $NETWORK_DEVICE -j MASQUERADE

# Enable IPv4 forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Run OpenVPN
sudo ip netns exec musicbee_ns openvpn --config $OPENVPN_CONF &
openvpn_pid=$!

# Give OpenVPN some time to initialize...
sleep 6

# Set up tunneling from inside the network namespace into the host
sudo ip netns exec musicbee_ns ip route add 127.0.0.1/32 via 10.200.1.254

# Run the Discord IPC bridge inside the network namespace
sudo ip netns exec musicbee_ns bash -c "sudo -u $USERNAME env \
    XDG_RUNTIME_DIR='/run/user/$USER_ID' \
    WINEPREFIX=$WINEPREFIX \
    HOME=$HOME \
    wine $IPC_BRIDGE" &
    bridge_pid=$!

# Run MusicBee inside the network namespace
sudo ip netns exec musicbee_ns bash -c "
    sudo -u $USERNAME env \
    USER=$USERNAME \
    XDG_SESSION_TYPE=user \
    XDG_RUNTIME_DIR='/run/user/$USER_ID' \
    PULSE_LATENCY_MSEC=60 \
    WINEPREFIX=$WINEPREFIX \
    HOME=$HOME \
    wine $MUSICBEE" &

# Give MusicBee some time to start, and find its PID
sleep 7
musicbee_pid=$(pgrep -f 'MusicBee.exe')

# Wait for MusicBee to exit
while [ -d "/proc/$musicbee_pid" ]; do
  sleep 1 & wait $!
done

# Usually the bridge ends itself, but just in case we should try kill it
kill $bridge_pid

# Make sure to kill the openvpn instance we created
kill $openvpn_pid
