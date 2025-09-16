# Follow up on failoverConfig.rsc script

# Extract and reassign some IPs from Address-list WAN1 and WAN2 to WAN3
:global listWAN1;
:global listWAN2;

:local set1WAN3 [:pick $listWAN1 0 6];
:local set2WAN3 [:pick $listWAN2 0 3];

:foreach ip in=$set1WAN3 do={ 
    /ip firewall address-list add list=WAN3 address=$ip
}

:foreach ip in=$set2WAN3 do={ 
    /ip firewall address-list add list=WAN3 address=$ip
 }

# Create firewall mangle rule to mark these IPs and forward them through WAN3 (new ISP)

/ip firewall mangle add chain=prerouting action=mark-routing src-address-list=WAN3 new-routing-mark=WAN3 passthrough=yes

# Configure recursive routing for the new ISPs connected Interface

/ip route 
add dst-address=8.8.8.8 gateway=192.168.2.1 scope=10

add dst-address=0.0.0.0/0 gateway=8.8.8.8 check-gateway=ping distance=1 routing-mark=WAN3
add dst-address=0.0.0.0/0 gateway=9.9.9.9 distance=2 routing-mark=WAN3

# NAT rule to translate IPs marked
/ip firewall nat 
add chain=srcnat action=masquerade src-address-list=WAN3 out-interface=eth2
add chain=srcnat action=masquerade src-address-list=WAN3 out-interface=eth1
add chain=srcnat action=masquerade src-address-list=WAN3 out-interface=eth3
add chain=srcnat action=masquerade src-address-list=WAN1 out-interface=eth2
add chain=srcnat action=masquerade src-address-list=WAN2 out-interface=eth2
