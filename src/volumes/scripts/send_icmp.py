#!/home/figaro/Programms/Github_Projects/ISSG_Projects/SAND5GAutomations/snort_complete/fileagent/app_venv/bin/python
from scapy.all import IP, ICMP, send, conf, get_if_addr
import time

# Hardoding interface
interface = "wlp0s20f3"
# Get the default interface
# interface = conf.iface

# Get the IP address of the interface to use as the destination
destination = get_if_addr(interface)

print(f"Destination IP: {destination} - Interface: {interface}")

ips = [
    "45.76.215.10",
    "167.179.91.0",
    "45.32.116.0",
    "207.148.24.0",
    "172.104.79.0",
    "45.33.77.0",
    "139.162.156.0",
    "172.104.236.0",
    "172.104.129.0",
    "202.79.165.195",
    "51.69.100.65",
    "103.119.155.27",
]

# Initialize a counter for packet number
packet_number = 1

# Send a packet for each IP address in the list
for ip in ips:
    # Create the packet with source and destination IPs
    packet = IP(src=ip, dst=destination) / ICMP()

    # Send the packet
    send(packet)

    # Print message with the current packet number
    print(f"Sent packet {packet_number}")

    # Increment the counter for the next packet
    packet_number += 1

    # Wait for 1 second before sending the next packet
    time.sleep(1)
