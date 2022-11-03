# mptcp_linux_kernel_experiments
The following repository consists of experiment scripts to emulate mptcp in the linux network namespaces. It makes use of the upstream version mptcp implementaion in the linux kernel.

### Topology (4-Node.sh):
![MPTCP_4node drawio (1)](https://user-images.githubusercontent.com/53138315/199648303-36ef3aa2-a2db-402f-908d-51f2ea8ef6a3.png)


### Pre-requisites:
- Ubuntu 22.10 machine (kernel version 5.19 or above) with iproute2 installed
- Install build-essential, git, iperf, iperf3 packages in the Ubuntu machine 
    ```bash
    sudo apt install build-essential git iperf iperf3
    ```
- Install [mptcpd](https://github.com/intel/mptcpd)  for userspace path management

### Experiment - 1 (using mptcp-tools and ip mptcp):
- **Step-1:** Clone the GitHub repository containing mptcp-tools (Note: installation is not required)
   ```bash
   git clone https://github.com/pabeni/mptcp-tools
   ```
- **Step-2:** Copy `4-Node.sh` file to the Ubuntu machine (it is fine to keep this file anywhere in the system)
- **Step-3:** Run the `4-Node.sh` file
   ```bash
   sudo sh 4-Node.sh
   ```
- **Step-4:** Open two terminals or two tabs in the same terminal.
- **Step-5:** On any one of the terminals/tabs, run the `iperf` or `iperf3` server in `h2` (Note: first change directory to `mptcp-tools/use_mptcp`, and then run the iperf/iperf3 server).
   ```bash
   cd mptcp-tools/use_mptcp 
   sudo ./use_mptcp.sh ip netns exec h2 iperf -s
  ```
- **Step-6:** On the second terminals/tab, run the `iperf` or `iperf3` client in `h1` (Note: first change directory to `mptcp-tools/use_mptcp`, and then run the iperf/iperf3 client).
   ```bash
   cd mptcp-tools/use_mptcp
   sudo ./use_mptcp.sh ip netns exec h1 iperf -c 10.0.1.2
    ```
    
### Experiment - 2 (using mptcpize and ip mptcp):
- **Step-1:** Run the following command to install `mptcpize`
   ```bash
   sudo apt install mptcpize
   ```
- **Step-2:** Copy `4-Node.sh` file to the Ubuntu machine (it is fine to keep this file anywhere in the system)
- **Step-3:** Run the `4-Node.sh` file
   ```bash
   sudo sh 4-Node.sh
   ```
- **Step-4:** Open two terminals or two tabs in the same terminal.
- **Step-5:** On any one of the terminals/tabs, run the `iperf` or `iperf3` server in `h2` 
   ```bash
   sudo mptcpize run ip netns exec h2 iperf -s
   ```
- **Step-6:** On the second terminals/tab, run the `iperf` or `iperf3` client in `h1`.
   ```bash
   sudo mptcpize run ip netns exec h1 iperf -c 10.0.1.2
   ```
   
### Expected output: 
The speed of data transfer between ‘h1’ and ‘h2’ should be more than 10Mbps.
 
### Analysis using Wireshark:
Repeat Step 4.
Before you do Step 5, do the following sub-steps:
- **Step 4a:** Open additional two terminals/tabs (so now the total is: 4 terminals/tabs)
- **Step 4b:** Run wireshark on the client `h1`.
   ```bash
   sudo ip netns exec h1 wireshark
   ```
- **Step 4c:** Select first interface `eth1a` from the list of interfaces in wireshark.
- **Step 4d:** Similarly run wireshark on the second interface `eth2a` of client `h1`.

Complete Step 5 and 6.
   
*NOTE: Experiments on other varients of network topologies are present in folder `Variants`. Its description is present in their respective scripts.*

