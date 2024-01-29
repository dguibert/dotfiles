#!/usr/bin/env python
# https://blog.fugoes.xyz/2018/02/03/Run-Babeld-over-Wireguard.html
import random

def random_mac():
    digits = [0x00, 0x16, 0x3e, random.randint(0x00, 0x7f), random.randint(0x00, 0xff), random.randint(0x00, 0xff)]
    return ":".join(map(lambda x: "%02x" % x, digits))

def mac_to_ipv6(mac):
    parts = mac.split(":")
    parts.insert(3, "ff")
    parts.insert(4, "fe")
    parts[0] = "%x" % (int(parts[0], 16) ^ 2)
    ipv6_parts = []
    for i in range(0, len(parts), 2):
        ipv6_parts.append("".join(parts[i:i + 2]))
    return "fe80::%s/64" % (":".join(ipv6_parts))

def random_ipv6():
    return mac_to_ipv6(random_mac())

if __name__ == "__main__":
    print(random_ipv6(), end="")

