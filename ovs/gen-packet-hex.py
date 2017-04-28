#!/usr/bin/env python
import binascii
from scapy.all import *

pkt=Ether(dst="02:ac:10:ff:00:22",src="02:ac:10:ff:00:11")/IP(dst="172.16.255.22",src="172.16.255.11", ttl=10)/ICMP()
print binascii.hexlify(str(pkt))
