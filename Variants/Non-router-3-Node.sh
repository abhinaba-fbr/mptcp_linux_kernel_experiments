###############################################################
# Topology
#  _______    5mbit, 5ms     _______   5mbit, 5ms     _______
# |       |-----------------|  r1   |----------------|       |
# |  h1   |                 |_______|                |   h2  |
# |       |                                          |       |
# |       |                                          |       |
# |_______|------------------------------------------|_______|
#	                  10mbit, 10ms       
##############################################################

#!/bin/sh

# Create four network namespaces: h1 and h2
ip netns add h1
ip netns add h2
ip netns add r1

# Disable the reverse path filtering
sysctl -w net.ipv4.conf.all.rp_filter=0

# Enable MPTCP on both the network namespaces
ip netns exec h2 sysctl -w net.mptcp.enabled=1
ip netns exec h1 sysctl -w net.mptcp.enabled=1

# Configuring the C flag
ip netns exec h1 sysctl -w net.mptcp.allow_join_initial_addr_port=1
ip netns exec h2 sysctl -w net.mptcp.allow_join_initial_addr_port=1

# Create two virtual ethernet (veth) pairs
ip link add eth1a netns h1 type veth peer eth1b netns r1
ip link add eth2a netns h1 type veth peer eth2b netns h2
ip link add eth3a netns r1 type veth peer eth3b netns h2

# Assign IP address to each interface on h1
ip -n h1 address add 10.0.0.1/24 dev eth1a
ip -n h1 address add 192.168.0.1/24 dev eth2a

# Assign IP address to each interface on r1
ip -n r1 address add 10.0.0.2/24 dev eth1b
ip -n r1 address add 10.0.1.1/24 dev eth3a

# Assign IP address to each interface on h2
ip -n h2 address add 10.0.1.2/24 dev eth3b
ip -n h2 address add 192.168.0.2/24 dev eth2b

# Set the data rate and delay on the veth devices at h1
ip netns exec h1 tc qdisc add dev eth1a root netem delay 5ms rate 5mbit
ip netns exec h1 tc qdisc add dev eth2a root netem delay 10ms rate 10mbit

# Set the data rate and delay on the veth devices at r1
ip netns exec r1 tc qdisc add dev eth3a root netem delay 5ms rate 5mbit
ip netns exec r1 tc qdisc add dev eth1b root netem delay 5ms rate 5mbit

# Set the data rate and delay on the veth devices at r1
ip netns exec h2 tc qdisc add dev eth3b root netem delay 5ms rate 5mbit
ip netns exec h2 tc qdisc add dev eth2b root netem delay 10ms rate 10mbit

# Turn ON all ethernet devices
ip -n h1 link set eth1a up
ip -n h1 link set eth2a up
ip -n r1 link set eth1b up
ip -n r1 link set eth3a up
ip -n h2 link set eth3b up
ip -n h2 link set eth2b up

# Define subflows for MPTCP
ip -n h1 mptcp endpoint flush
ip -n h1 mptcp limits set subflow 2 add_addr_accepted 2

ip -n h2 mptcp endpoint flush
ip -n h2 mptcp limits set subflow 2 add_addr_accepted 2

# Can change these parameters for adjust who initiates the join subflow
# ip -n h2 mptcp endpoint add 192.168.1.2 dev eth2b id 1 signal
# ip -n h1 mptcp endpoint add 192.168.0.1 dev eth2a id 1 subflow
# ip -n h1 mptcp endpoint add 10.0.0.1 dev eth1a id 1 subflow
ip -n h2 mptcp endpoint add 10.0.1.2 dev eth3b id 1 signal

# Enable IP forwarding
ip netns exec r1 sysctl -w net.ipv4.ip_forward=1

# Create two routing tables for two interace in h1
ip netns exec h1 ip rule add from 10.0.0.1 table 1
ip netns exec h1 ip rule add from 192.168.0.1 table 2

# Configure the two routing tables of h1
ip netns exec h1 ip route add 10.0.0.0/24 dev eth1a scope link table 1
ip netns exec h1 ip route add default via 10.0.0.2 dev eth1a table 1

ip netns exec h1 ip route add 192.168.0.0/24 dev eth2a scope link table 2
ip netns exec h1 ip route add default via 192.168.0.2 dev eth2a table 2

# Create two routing tables for two interace in h2
ip netns exec h2 ip rule add from 10.0.1.2 table 3
ip netns exec h2 ip rule add from 192.168.0.2 table 4

# Configure the two routing tables
ip netns exec h2 ip route add 10.0.1.0/24 dev eth3b scope link table 3
ip netns exec h2 ip route add default via  10.0.1.1 dev eth3b table 3

ip netns exec h2 ip route add 192.168.0.0/24 dev eth2b scope link table 4
ip netns exec h2 ip route add default via 192.168.0.1 dev eth2b table 4

# Global Default route for h1 and h2
ip netns exec h1 ip route add default scope global nexthop via 10.0.0.2 dev eth1a
ip netns exec h2 ip route add default scope global nexthop via 10.0.1.1 dev eth3b
