# download speed test script - To check download bandwidth

# A list of CDNs
:local cdnServers {'los.download.datapacket.com', 'speedtest.tele2.net', 'nbg1-speed.hetzner.com'}

# direct file links from each CDN in the list array
:local cdnLinks {"https://nbg1-speed.hetzner.com/1GB.bin", 'http://speedtest.tele2.net/1GB.zip', 'https://los.download.datapacket.com/1000mb.bin'};

# the expected file size to download from each CDN 
:local hetznerFileSize (1048576 * 1024);
:local tele2FileSize (1048576 * 1024);
:local dataPacketFileSize (1048576 * 1024);

# Send out ping to target servers and collect the RTTs of both and then use the CDN with lowest RTT

:local serverRTTs [:toarray ""];
:local indicator 0;

:foreach cdn in=$cdnServers do={
  :local rtt [/ping $cdn count=1];

  # get the average RTT from the ping of each CDN
  :set serverRTTs ($serverRTTs, ($rtt->$rtt.avg) = ($indicator))

  :set indicator ($indicator + 1);
}

:local total [:len $serverRTTs];

:local faveCDN (($serverRTTs->0 + $serverRTTs->1 + $serverRTTs->2 +$serverRTTs->3)/$total)

# After getting the average RTT, we can select the CDN with the lowest RTT



# collate the duration of each download from CDN selected

:local durations ;

:for i from=1 to=5 do={ 

  :local initDuration [/system clock get time];

  /tool fetch url $targetServer mode=https keep-result=no;

  :local nextDuration [:put [/system clock get time]];
  :local duration ($nextDuration-initDuration)
  :set durations ($durations, $duration)

}

# Get the average 

:local averageDuration (($durations->0 +$durations->1 + $durations->2 + $durations->3 +$durations->4)/5);

:if ($averageDuration > 0) do={
  :local speed ($fileSize / $averageDuration);
  :put ("Download speed: " . $speed . " bytes/sec");
  :if ($speed < 5000000) do={
    :put "Speed is below 5 Mbps, consider checking your connection.";
    /ip route set [find where comment="WAN1_main"] distance=10; # Change the administrative distance to trigger a failover switch
  } else={
    :put "Speed is acceptable.";
  }
}
:else={
  :put "Not calculation is possible as the speed test resulted in zero elapsed time.";
}

