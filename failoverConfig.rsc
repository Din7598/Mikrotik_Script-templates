# This is the failover configuration for Mikrotik v6.49.10 template developed for YANNA APARTMENT by Khaliques

# Modify to include the source subnets you're working with 
:local list_WAN1_Starlink {'10.0.0.0/27';
'10.0.0.64/27';
'10.0.0.128/27';
'10.0.0.192/27';
'10.0.1.0/27';
'10.0.1.64/27';
'10.0.1.128/27';
'10.0.1.192/27';
'10.0.2.0/27';
'10.0.2.64/27';
'10.0.2.128/27';
'10.0.2.192/27'
};

:local list_WAN2_WoW {'10.0.0.32/27';
'10.0.0.95/27';
'10.0.0.160/27';
'10.0.0.224/27';
'10.0.1.32/27';
'10.0.1.96/27';
'10.0.1.160/27';
'10.0.1.224/27';
'10.0.2.32/27';
'10.0.2.96/27';
'10.0.2.160/27';
'10.0.2.224/27'
};

# Base containment for subnet lists
:local collection {$list_WAN1_Starlink; $list_WAN2_WoW};

# Configure IP address prefix group 
:foreach iprefix in=collection do={
    :if ($iprefix = $list_WAN1_Starlink) do={
        :foreach ipAdd in=$iprefix do={ 
            /ip firewall address-list add list=WAN1 address=$ipAdd
         }
    }else={
        :foreach ipAdd in=$iprefix do={
            /ip firewall address-list add list=WAN2 address=$ipAdd
        }
    }
} 

# Configure Firewall mangle to match packets based on source IP address and then assign them their designated route
/ip firewall mangle add chain=prerouting action=mark-routing src-address-list=WAN1 new-routing=ROUTE1 passthrough=yes

/ip firewall mangle add chain=prerouting action=mark-routing src-address-list=WAN2 new-routing=ROUTE2 passthrough=yes

# Configure private IP address dynamic translation as packet egress through WAN interfaces
/ip firewall add chain=srcnat out-interface=eth-WAN src-address-list=WAN1 action=masquerade
/ip firewall add chain=srcnat out-interface=eth-WAN src-address-list=WAN2 action=masquerade

/ip firewall add chain=srcnat out-interface=eth4 src-address-list=WAN1 action=masquerade
/ip firewall add chain=srcnat out-interface=eth4 src-address-list=WAN2 action=masquerade

# Configure recursive route for more robust load balancing 
/ip route
add dst-address=8.8.8.8 gateway=192.168.1.1 scope=10 target-scope=11 comment="WAN1 check route"
add dst-address=9.9.9.9 gateway=192.168.68.1 scope=10 target-scope=11 comment="WAN2 check route"

add dst-address=0.0.0.0/0 gateway=8.8.8.8 distance=1 comment="Primary WAN1 route for the router"
add dst-address=0.0.0.0/0 gateway=9.9.9.9 distance=2 comment="Backup WAN2 route for the router"

add dst-address=0.0.0.0/0 gateway=8.8.8.8 routing-mark=to-WAN1 check-gateway=ping comment='WAN1 - LAN1 main path'
add dst-address=0.0.0.0/0 gateway=9.9.9.9 distance=2 routing-mark=to-WAN1

add dst-address=0.0.0.0/0 gateway=9.9.9.9 routing-mark=to-WAN2 check-gateway=ping comment='WAN2 - LAN2 main path'
add dst-address=0.0.0.0/0 gateway=8.8.8.8 distance=2 routing-mark=to-WAN2

# Display details of the configuration
/ip route print detail; /ip firewall mangle print; /ip firewall nat print; /ip firewall address-list print