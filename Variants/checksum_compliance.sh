#######################################
# Topology
#  _______   10mbit, 5ms     _______
# |       |-----------------|       | 
# |  h1   |                 |   h2  |
# |_______|-----------------|_______|
#	       5mbit, 10ms	
#######################################

#!/bin/sh

#Create two network namespaces: h1 and h2
ip netns add h1
ip netns add h2

# Disable the reverse path filtering
sysctl -w net.ipv4.conf.all.rp_filter=0

# Enable MPTCP on both the network namespaces
ip netns exec h2 sysctl -w net.mptcp.enabled=1
ip netns exec h1 sysctl -w net.mptcp.enabled=1

# Configuring the checksum on both the namespaces
ip netns exec h1 sysctl -w net.mptcp.checksum_enabled=1
ip netns exec h2 sysctl -w net.mptcp.checksum_enabled=1

# Configuring C flag
ip netns exec h2 sysctl -w net.mptcp.checksum_enabled=1;

#Create two virtual ethernet (veth) pairs between h1 and h2
ip link add eth1a netns h1 type veth peer eth2a netns h2
ip link add eth1b netns h1 type veth peer eth2b netns h2

# Assign IP address to each interface on h1
ip -n h1 address add 10.0.0.1/24 dev eth1a
ip -n h1 address add 192.168.0.1/24 dev eth1b

# Assign IP address to each interface on h2
ip -n h2 address add 10.0.0.2/24 dev eth2a
ip -n h2 address add 192.168.0.2/24 dev eth2b

# Set the data rate and delay on the veth devices at h1
ip netns exec h1 tc qdisc add dev eth1a root netem delay 5ms rate 10mbit
ip netns exec h1 tc qdisc add dev eth1b root netem delay 10ms rate 5mbit

# Set the data rate and delay on the veth devices at h2
ip netns exec h2 tc qdisc add dev eth2a root netem delay 5ms rate 10mbit
ip netns exec h2 tc qdisc add dev eth2b root netem delay 10ms rate 5mbit

#Turn ON all ethernet devices
ip -n h1 link set eth1a up
ip -n h1 link set eth1b up
ip -n h2 link set eth2a up
ip -n h2 link set eth2b up

# Define subflows for MPTCP
ip -n h1 mptcp endpoint flush
ip -n h1 mptcp limits set subflow 1 add_addr_accepted 1

ip -n h2 mptcp endpoint flush
ip -n h2 mptcp limits set subflow 1 add_addr_accepted 1

# Path Management 'in-kernel' using ip mptcp
ip -n h1 mptcp endpoint add 192.168.0.1 dev eth1b id 1 subflow
# ip -n h2 mptcp endpoint add 192.168.0.2 dev eth2b id 1 signal
# ip -n h2 mptcp endpoint add 192.168.0.2 dev eth2b id 1 subflow
