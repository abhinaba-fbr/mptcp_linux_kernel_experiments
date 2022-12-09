#!/bin/sh

# Delete existing namespaces
ip --all netns del

# Creating two namespaces
ip netns add h1
ip netns add h2

# creating the veth pair anc connecting them
ip link add eth0 type veth peer eth1
ip link set eth0 netns h1
ip link set eth1 netns h2

# Activating the interface cards in each namespaces
ip netns exec h1 ip link set lo up
ip netns exec h1 ip link set eth0 up
ip netns exec h2 ip link set lo up
ip netns exec h2 ip link set eth1 up

# Assigning IP address to the interfaces
ip netns exec h1 ip address add 10.0.0.1/24 dev eth0
ip netns exec h2 ip address add 10.0.0.2/24 dev eth1

# Adding delay and error, and reordering the packets
ip netns exec h1 tc qdisc add dev eth0 root netem delay 100ms 10ms 20% rate 10mbit corrupt 10% 50% reorder 25% 50%
ip netns exec h2 tc qdisc add dev eth1 root netem delay 100ms 10ms 20% rate 10mbit corrupt 10% 50% reorder 25% 50%

