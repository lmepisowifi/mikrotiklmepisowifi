# mar/13/2026 16:19:57 by RouterOS 6.49.19
# software id = G8LT-KU8L
#
# model = RB941-2nD
# serial number = HGN09Q6176C
/interface ethernet
set [ find default-name=ether1 ] comment=wan loop-protect=on name=ether1.ISP
set [ find default-name=ether2 ] name=ether2.HS
set [ find default-name=ether3 ] comment="outdoor access point" name=\
    ether3.HS
set [ find default-name=ether4 ] comment=lan name=ether4.LAN
/interface bridge
add comment="(bridge)" name="Vendo 1"
/interface vlan
add comment="(vlan10)" interface="Vendo 1" name="Vendo 2" vlan-id=10
add comment="(vlan 11)" interface="Vendo 1" name="Vendo 3" vlan-id=11
add comment="(vlan 12)" interface="Vendo 1" name="Vendo 4" vlan-id=12
/ip hotspot profile
set [ find default=yes ] login-by=cookie,http-chap,http-pap,mac-cookie
add hotspot-address=10.0.0.1 login-by=http-chap,http-pap name="(HS PROFILE)"
/ip hotspot user profile
set [ find default=yes ] add-mac-cookie=no keepalive-timeout=3m name=\
    autospeedlimit on-login="# Get User Data\
    \n:local date [ /system clock get date]\
    \n:local time [ /system clock get time]\
    \n\
    \n:local aUsrNote [/ip hotspot user get \$user comment];\
    \n:local aUsrNote [:toarray \$aUsrNote];\
    \n:local iSaleAmt [:tonum (\$aUsrNote->1)];\
    \n:local totaltime [/ip hotspot user get [find name=\$user] limit-uptime];\
    \n:local cpuusage [/system resource get cpu-load];\
    \n:local freeRam [/system resource get free-memory];\
    \n:local ramMB (\$freeRam / 1048576);\
    \n:local ramdecimal (\$ramMB % 10);\
    \n\
    \n    # Get Queue Stats (Only if specific queues exist)\
    \n# Get Queue Stats\
    \n:local queueName \"PCQ simple queue\";\
    \n:local dnMbps 0;\
    \n:local upMbps 0;\
    \n\
    \n:do {\
    \n    :local qData [/queue simple print stats as-value where name=\$queueN\
    ame];\
    \n    :if ([:len \$qData] > 0) do={\
    \n        :set dnMbps (([:pick \$qData 0]->\"rx-rate\") / 1000000);\
    \n        :set upMbps (([:pick \$qData 0]->\"tx-rate\") / 1000000);\
    \n    }\
    \n} on-error={}\
    \n\
    \n\
    \n:local limit 0s;\
    \n:local uptime 0s;\
    \n:local remainingt 0s;\
    \n:local totaluptime 0s;\
    \n:local mac \$\"mac-address\";\
    \n:local macNoCol (\"\$[:pick \$mac 0 2]\$[:pick \$mac 3 5]\$[:pick \$mac \
    6 8]\$[:pick \$mac 9 11]\$[:pick \$mac 12 14]\$[:pick \$mac 15 17]\");\
    \n # Get Device Name (Optimized trimming)\
    \n:local deviceName [/ip dhcp-server lease get [find mac-address=\$mac] ho\
    st-name];\
    \n:if ([:len \$deviceName] = 0) do={ :set deviceName \"N/A\"; }\
    \n\t\
    \n:do {\
    \n    :set limit [/ip hotspot user get [find name=\$user] limit-uptime];\
    \n    :set uptime [/ip hotspot user get [find name=\$user] uptime];\
    \n    :set remainingt (\$limit - \$uptime);\
    \n    :set totaluptime (\$limit - \$remainingt);\
    \n} on-error={ \
    \n    :log warning \"time variable error!\";\
    \n};\
    \n\
    \n\
    \n### enable telegram notification, change from 0 to 1 if you want to enab\
    le telegram\
    \n:local isTelegram 1;\
    \n:local iTBotToken [/system script get [find name=\"bottoken\"] source];\
    \n:local iTGrChatID [/system script get [find name=\"chatid\"] source];\
    \n### hotspot folder for HEX put flash/hotspot for haplite put hotspot onl\
    y\
    \n:local HSFilePath \"hotspot\";\
    \n:local uactive [/ip hotspot active print count-only];\
    \n\
    \n:local todaysales [:tonum [/system script get todayincome source]];\
    \n:local mnthlysales [:tonum [/system script get monthlyincome source]];\
    \n:local yearlysales [:tonum [/system script get yearlyincome source]];\
    \n\
    \n\
    \n\
    \n:local iDailySales (\$iSaleAmt + \$todaysales);\
    \n/system script set todayincome source=\"\$iDailySales\";\
    \n:local iMonthSales (\$iSaleAmt + \$mnthlysales);\
    \n/system script set monthlyincome source=\"\$iMonthSales\";\
    \n:local iYearSales (\$iSaleAmt + \$yearlysales);\
    \n/system script set yearlyincome source=\"\$iYearSales\";\
    \n\
    \n:local hotspotFolder \"hotspot\";\
    \n:local com [/ip hotspot user get [find name=\$user] comment];\
    \n:if (\$com=\"\") do={\
    \n:if (\$isTelegram=1) do={\
    \n    :local loginMessage (\"\$user%20resumed%20time,%20remaining%20time%2\
    0is%20\$remainingt%0AActive%20Users:%20\$uactive\");\
    \n    /tool fetch url=\"https://api.telegram.org/bot\$iTBotToken/sendMessa\
    ge\?chat_id=\$iTGrChatID&text=\$loginMessage\" keep-result=no;\
    \n}\
    \n}\
    \n/ip hotspot user set comment=\"\" \$user;\
    \n:if (\$com!=\"\") do={\
    \n\t:local validity [:pick \$com 0 [:find \$com \",\"]];\
    \n\t:if ( \$validity!=\"0m\" ) do={\
    \n\t\t:local sc [/sys scheduler find name=\$user]; :if (\$sc=\"\") do={ :l\
    ocal a [/ip hotspot user get [find name=\$user] limit-uptime]; :local c (\
    \$validity); :local date [ /system clock get date]; /sys sch add name=\"\$\
    user\" disable=no start-date=\$date interval=\$c on-event=\"/ip hotspot us\
    er remove [find name=\$user]; /ip hotspot active remove [find user=\$user]\
    ; /ip hotspot cookie remove [find user=\$user]; /system sche remove [find \
    name=\$user]; /file remove \\\"\$hotspotFolder/data/\$macNoCol.txt\\\";\" \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon; :\
    delay 2s; } else={ :local sint [/sys scheduler get \$user interval]; :if (\
    \_\$validity!=\"\" ) do={ /sys scheduler set \$user interval (\$sint+\$val\
    idity); } };\
    \n\t}\
    \n\
    \n\t:local fileScheduler \"FILE\$macNoCol\";\
    \n\t:local fsc [/sys scheduler find name=\$fileScheduler];\
    \n\t:local validUntil [/sys scheduler get \$user next-run];\
    \n\t:if (\$fsc!=\"\") do={\
    \n\t\t/system scheduler remove [find name=\$fileScheduler];\
    \n\t}\
    \n\t:do { /system scheduler add name=\"\$fileScheduler\" interval=5 \\\
    \n\t\t\tstart-date=[/system clock get date] start-time=[/system clock get \
    time] disable=no \\\
    \n\t\t\tpolicy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,\
    romon \\\
    \n\t\t\ton-event=(\"/system scheduler set \$fileScheduler interval 0;\\r\\\
    n\".\\\
    \n\t\t\t\t\t\t\"/file print file=\\\"\$hotspotFolder/data/\$macNoCol\\\" w\
    here name=\\\"dummyfile\\\";\\r\\n\".\\\
    \n\t\t\t\t\t\t\":delay 1s;\\r\\n\".\\\
    \n\t\t\t\t\t\t\"/file set \\\"\$hotspotFolder/data/\$macNoCol\\\" contents\
    =\\\"\$user#\$validUntil\\\";\\r\\n\".\\\
    \n\t\t\t\t\t\t\":log warning \\\"juanfimonitoring.com ==> parallel script \
    executed successfully.\\\";\\r\\n\")\
    \n\t\t} on-error={ :log error \"juanfimonitoring.com ==> parallel script c\
    reation error.\"; };\
    \n:local currentday [:pick \$date 4 6]\
    \n:local estimatedperday (\$mnthlysales / \$currentday)\
    \n:local estimatedpermonth (\$estimatedperday * 30)\
    \n:local iValidUntil [/system scheduler get \$user next-run];\
    \n:local loginMessage (\"Information:%0ACoin:%20\E2\82\B1%20\$iSaleAmt%0AU\
    ser:%20\$user%0ADevice%20Name:%20\$deviceName%0ATotal%20Time:%20\$totaltim\
    e%0AUsed%20Time:%20\$totaluptime%0ARemaining%20Time:%20\$remainingt%0AExpi\
    res%20On:%20\$iValidUntil%0A%0ACurrent:%0AToday%20Sales:%20\E2\82\B1%20\$i\
    DailySales%0AIncome%20This%20Month:%20\E2\82\B1%20\$iMonthSales%0AIncome%2\
    0This%20Year:%20\$iYearSales%0AActive%20Users:%20\$uactive%0ADate%20%26%20\
    Timestamp:%20\$date%20\$time%0A%0ASystem%20Information:%0ACPU%20Usage:%20\
    \$cpuusage%25%0ARemaining%20Memory:%20\$ramMB.\$ramdecimal%20MB%0ACurrent%\
    20Throughput:%20\$dnMbps%20mbps%2F\$upMbps%20mbps%0A%0AEstimates:%0AEstima\
    ted%20Per%20Day:%20\E2\82\B1%20\$estimatedperday%0AEstimated%20Per%20Month\
    :%20\E2\82\B1%20\$estimatedpermonth%0A%0A(Note:%20The%20Estimates%20are%20\
    not%20the%20current%20sales.)\");\
    \n    /tool fetch url=\"https://api.telegram.org/bot\$iTBotToken/sendMessa\
    ge\?chat_id=\$iTGrChatID&text=\$loginMessage\" keep-result=no;\
    \n}\
    \n\
    \n:local cmac \$\"mac-address\"\
    \n:foreach AU in=[/ip hotspot active find user=\"\$username\"] do={\
    \n\t:local amac [/ip hotspot active get \$AU mac-address];\
    \n\t:if (\$cmac!=\$amac) do={  /ip hotspot active remove [/ip hotspot acti\
    ve find mac-address=\"\$amac\"]; }\
    \n}\
    \n\
    \n\
    \n" on-logout=":local com [/ip hotspot user get [find name=\$user] comment\
    ];\
    \n:local hotspotFolder \"hotspot\";\
    \n:local mac \$\"mac-address\";\
    \n:local macNoCol;\
    \n:for i from=0 to=([:len \$mac] - 1) do={ \
    \n  :local char [:pick \$mac \$i]\
    \n  :if (\$char = \":\") do={\
    \n\t:set \$char \"\"\
    \n  }\
    \n  :set macNoCol (\$macNoCol . \$char)\
    \n}\
    \n:if ([/ip hotspot user get [/ip hotspot user find where name=\"\$user\"]\
    \_limit-uptime] <= [/ip hotspot user get [/ip hotspot user find where name\
    =\"\$user\"] uptime]) do={\
    \n    /ip hotspot user remove \$user;\
    \n\t/file remove \"\$hotspotFolder/data/\$macNoCol.txt\";\
    \n\t/system sche remove [find name=\$user];\
    \n}\
    \n\
    \n:local fileScheduler \"FILE\$macNoCol\";\
    \n:local fsc [/sys scheduler find name=\$fileScheduler];\
    \n:if (\$fsc!=\"\") do={\
    \n\t/system scheduler remove [find name=\$fileScheduler];\
    \n}\
    \n:local retryScheduler \"RETRY\$macNoCol\"\
    \n:local fsc [/sys scheduler find name=retryScheduler];\
    \n:if (\$fsc!=\"\") do={\
    \n\t/system scheduler remove [find name=retryScheduler];\
    \n}\
    \n### enable telegram notification, change from 0 to 1 if you want to enab\
    le telegram\
    \n:local isTelegram 1;\
    \n###replace telegram token\
    \n:local iTBotToken [/system script get [find name=\"bottoken\"] source];\
    \n\
    \n:local iTGrChatID [/system script get [find name=\"chatid\"] source];\
    \n# Check for session timeout and send notification\
    \n:if (\$cause=\"session timeout\") do={\
    \n  :local timeoutMessage (\"\$user ran out of time!\");\
    \n  /tool fetch url=\"https://api.telegram.org/bot\$iTBotToken/sendMessage\
    \?chat_id=\$iTGrChatID&text=\$timeoutMessage\" keep-result=no;\
    \n}\
    \n\
    \n:if (\$com=\"\") do={\
    \n:if (\$isTelegram=1) do={\
    \n:if (\$cause=\"user request\") do={  \
    \n  :local timeoutMessage (\"\$user paused time.\");\
    \n  /tool fetch url=\"https://api.telegram.org/bot\$iTBotToken/sendMessage\
    \?chat_id=\$iTGrChatID&text=\$timeoutMessage\" keep-result=no;\
    \n}\
    \n}\
    \n}\
    \n\
    \n\
    \n\
    \n:if (\$cause=\"keepalive timeout\") do={\
    \n    :local timeoutMessage (\"automatically paused time for \$user\");\
    \n    /tool fetch url=\"https://api.telegram.org/bot\$iTBotToken/sendMessa\
    ge\?chat_id=\$iTGrChatID&text=\$timeoutMessage\" keep-result=no;\
    \n    \
    \n}\
    \n\
    \n:if (\$cause=\"admin reset\") do={\
    \n  \
    \n  :local timeoutMessage (\"admin kicked \$user\");\
    \n  /tool fetch url=\"https://api.telegram.org/bot\$iTBotToken/sendMessage\
    \?chat_id=\$iTGrChatID&text=\$timeoutMessage\" keep-result=no;\
    \n}\
    \n\
    \n:local iValidUntil [/system scheduler get \$user next-run];\
    \n\
    \n:if ([:len [/ip hotspot user find where name=\$user]] > 0) do={\
    \n    :if ([:len [/file find name=\"hotspot/data/\$user.txt\"]] = 0) do={\
    \n        :local myfile \"hotspot/data/\$user.txt\";\
    \n        /file print file=\$myfile;\
    \n        :delay 0;\
    \n        :local cont \"\$user#\$iValidUntil\";\
    \n        /file set \$myfile contents=\$cont;\
    \n    }\
    \n}\
    \n"
/ip pool
add name=pool.hs ranges=10.0.0.5-10.0.0.254
add name=pool.lan ranges=192.168.12.2-192.168.12.254
add name=vlan.10.pool.hs ranges=10.0.1.4-10.0.1.254
add name=vlan.11.pool.hs ranges=10.0.2.4-10.0.2.254
add name=vlan.12.pool.hs ranges=10.0.3.4-10.0.3.254
/ip dhcp-server
add address-pool=pool.hs disabled=no interface="Vendo 1" lease-time=1d name=\
    dhcp1
add address-pool=pool.lan disabled=no interface=ether4.LAN lease-time=1d \
    name=dhcp2
add address-pool=vlan.10.pool.hs disabled=no interface="Vendo 2" lease-time=\
    1d name=dhcp3
add address-pool=vlan.11.pool.hs disabled=no interface="Vendo 3" lease-time=\
    1d name=dhcp4
add address-pool=vlan.12.pool.hs disabled=no interface="Vendo 4" lease-time=\
    1d name=dhcp5
/ip hotspot
add address-pool=pool.hs addresses-per-mac=1 disabled=no interface="Vendo 1" \
    name="HS SERVER" profile="(HS PROFILE)"
add address-pool=vlan.10.pool.hs addresses-per-mac=1 disabled=no interface=\
    "Vendo 2" name="HS SERVER VLAN10" profile="(HS PROFILE)"
add address-pool=vlan.11.pool.hs addresses-per-mac=1 disabled=no interface=\
    "Vendo 3" name="HS SERVER VLAN11" profile="(HS PROFILE)"
add address-pool=vlan.12.pool.hs addresses-per-mac=1 disabled=no interface=\
    "Vendo 4" name="HS SERVER VLAN12" profile="(HS PROFILE)"
/queue simple
add max-limit=30M/30M name="PCQ simple queue" queue=\
    pcq-upload-default/pcq-download-default target="Vendo 1"
add max-limit=30M/30M name="PCQ simple queue n2" queue=\
    pcq-upload-default/pcq-download-default target="Vendo 2"
add max-limit=30M/30M name="PCQ simple queue n3" queue=\
    pcq-upload-default/pcq-download-default target="Vendo 3"
add max-limit=30M/30M name="PCQ simple queue n4" queue=\
    pcq-upload-default/pcq-download-default target="Vendo 4"
/system logging action
set 0 memory-lines=500
set 1 disk-lines-per-file=500
/interface bridge port
add bridge="Vendo 1" interface=ether3.HS
add bridge="Vendo 1" disabled=yes interface=ether4.LAN
add bridge="Vendo 1" interface=ether2.HS
/ip neighbor discovery-settings
set discover-interface-list=!dynamic
/interface detect-internet
set internet-interface-list=all lan-interface-list=all wan-interface-list=all
/ip address
add address=10.0.0.1/24 interface="Vendo 1" network=10.0.0.0
add address=192.168.12.1/24 interface=ether4.LAN network=192.168.12.0
add address=10.0.1.1/24 comment="(vlan 10)" interface="Vendo 2" network=\
    10.0.1.0
add address=10.0.2.1/24 comment="(vlan 11)" interface="Vendo 3" network=\
    10.0.2.0
add address=10.0.3.1/24 comment="(vlan 12)" interface="Vendo 4" network=\
    10.0.3.0
/ip arp
add address=10.0.1.5 comment="(nodemcu, vlan10) change mac accordingly " \
    interface="Vendo 2" mac-address=84:F3:EB:CB:20:81
add address=10.0.2.5 comment="(nodemcu, vlan11) change mac accordingly " \
    interface="Vendo 3" mac-address=84:F3:EB:CB:20:78
add address=10.0.3.5 comment="(nodemcu, vlan12) change mac accordingly " \
    interface="Vendo 4" mac-address=84:F3:EB:CB:20:79
/ip cloud
set ddns-update-interval=1m update-time=no
/ip dhcp-client
add disabled=no interface=ether1.ISP script="# ===============================\
    =============================\
    \n# update_antiaccess.rsc\
    \n# Reads the current DHCP client gateway, then updates the\
    \n# \"antiaccessrouter\" firewall address-list entry to match it.\
    \n# ============================================================\
    \n\
    \n# --- 1. Get the gateway IP from the DHCP client ---\
    \n:local gatewayIp \"\"\
    \n\
    \n# Find the first active DHCP client entry and grab its gateway\
    \n:local dhcpId [/ip dhcp-client find where status=\"bound\"]\
    \n\
    \n:if ([:len \$dhcpId] > 0) do={\
    \n    :set gatewayIp [/ip dhcp-client get [:pick \$dhcpId 0] gateway]\
    \n} else={\
    \n    :log error \"update_antiaccess: no bound DHCP client found, aborting\
    .\"\
    \n    :error \"No active DHCP lease found.\"\
    \n}\
    \n\
    \n:log info \"update_antiaccess: DHCP gateway is -> \$gatewayIp\"\
    \n\
    \n# --- 2. Validate the gateway we got ---\
    \n:if ([:len \$gatewayIp] = 0) do={\
    \n    :log error \"update_antiaccess: gateway IP is empty, aborting.\"\
    \n    :error \"Gateway IP retrieved from DHCP client is empty.\"\
    \n}\
    \n\
    \n# --- 3. Find the entry in the \"antiaccessrouter\" address list ---\
    \n:local listId [/ip firewall address-list find where list=\"antiaccessrou\
    ter\"]\
    \n\
    \n:if ([:len \$listId] > 0) do={\
    \n\
    \n    :log info \"update_antiaccess: found antiaccessrouter entry, updatin\
    g to \$gatewayIp ...\"\
    \n\
    \n    # Update the first matching entry's address to the gateway IP\
    \n    /ip firewall address-list set [:pick \$listId 0] address=\$gatewayIp\
    \n\
    \n    :log info \"update_antiaccess: address-list entry updated successful\
    ly.\"\
    \n\
    \n} else={\
    \n    :log warning \"update_antiaccess: no entry found in address-list 'an\
    tiaccessrouter', skipping.\"\
    \n}\
    \n" use-peer-dns=no use-peer-ntp=no
/ip dhcp-server lease
add address=10.0.0.5 mac-address=84:F3:EB:1D:CC:8E server=dhcp1
/ip dhcp-server network
add address=10.0.0.0/24 gateway=10.0.0.1
add address=10.0.1.0/24 comment="hotspot network" gateway=10.0.1.1
add address=10.0.2.0/24 comment="hotspot network" gateway=10.0.2.1
add address=10.0.3.0/24 gateway=10.0.3.1
add address=192.168.12.0/24 gateway=192.168.12.1
/ip dns
set allow-remote-requests=yes cache-max-ttl=1h cache-size=250KiB servers=\
    1.1.1.1
/ip firewall address-list
add address=192.168.33.1 list=antiaccessrouter
add address=10.0.0.5 list=nodemcu
add address=10.0.1.5 list=nodemcu
add address=10.0.2.5 list=nodemcu
add address=10.0.3.5 list=nodemcu
/ip firewall filter
add action=accept chain=input comment=NodeMCUIP src-address=10.0.0.5
add action=accept chain=input comment=NodeMCUIP src-address=10.0.1.5
add action=accept chain=input comment=NodeMCUIP src-address=10.0.2.5
add action=accept chain=input comment=NodeMCUIP src-address=10.0.3.5
add action=accept chain=forward dst-address=10.0.0.0/24 src-address-list=\
    nodemcu
add action=accept chain=forward dst-address-list=nodemcu src-address=\
    10.0.0.0/24
add action=accept chain=forward dst-address-list=nodemcu src-address=\
    10.0.1.0/24
add action=accept chain=forward dst-address-list=nodemcu src-address=\
    10.0.2.0/24
add action=accept chain=forward dst-address-list=nodemcu src-address=\
    10.0.3.0/24
add action=passthrough chain=unused-hs-chain comment=\
    "place hotspot rules here" disabled=yes
add action=passthrough chain=unused-hs-chain comment=\
    "place hotspot rules here" disabled=yes
add action=drop chain=forward comment="anti access router" dst-address-list=\
    antiaccessrouter src-address=10.0.0.0/24
add action=drop chain=forward comment="anti access router" dst-address-list=\
    antiaccessrouter src-address=10.0.1.0/24
add action=drop chain=forward comment="anti access router" dst-address-list=\
    antiaccessrouter src-address=10.0.2.0/24
add action=drop chain=forward comment="anti access router" dst-address-list=\
    antiaccessrouter src-address=10.0.3.0/24
/ip firewall mangle
add action=change-ttl chain=postrouting new-ttl=set:1 out-interface="Vendo 1" \
    passthrough=no
/ip firewall nat
add action=masquerade chain=srcnat comment="masquerade hotspot network" \
    src-address=10.0.0.0/24
add action=masquerade chain=srcnat comment="masquerade hotspot network" \
    src-address=10.0.1.0/24
add action=masquerade chain=srcnat comment="masquerade hotspot network" \
    src-address=10.0.2.0/24
add action=masquerade chain=srcnat comment="masquerade hotspot network" \
    src-address=10.0.3.0/24
add action=masquerade chain=srcnat out-interface=ether1.ISP
/ip hotspot ip-binding
add address=10.0.0.5 comment="change mac according to nodemcu" disabled=yes \
    mac-address=84:F3:EB:1D:CC:8E server="HS SERVER" to-address=10.0.0.5 \
    type=bypassed
add address=10.0.1.5 comment="change mac according to nodemcu" disabled=yes \
    mac-address=FC:F5:C4:A6:DA:C5 server="HS SERVER" to-address=10.0.1.5 \
    type=bypassed
add address=10.0.2.5 comment="change mac according to nodemcu" disabled=yes \
    mac-address=FC:F5:C4:A6:DA:C5 server="HS SERVER" to-address=10.0.2.5 \
    type=bypassed
add address=10.0.3.5 comment="change mac according to nodemcu" disabled=yes \
    mac-address=FC:F5:C4:A6:DA:C5 server="HS SERVER" to-address=10.0.3.5 \
    type=bypassed
add address=10.0.0.6-10.0.0.254 comment=AUTH mac-address=EC:46:2C:96:FD:E3 \
    server="HS SERVER" type=bypassed
/ip hotspot walled-garden
add comment="place hotspot rules here" disabled=yes
/ip hotspot walled-garden ip
add action=accept comment=nodemcu disabled=no dst-address=10.0.0.5 \
    !dst-address-list !dst-port !protocol !src-address !src-address-list
add action=accept disabled=no dst-address=10.0.1.5 !dst-address-list \
    !dst-port !protocol !src-address !src-address-list
add action=accept disabled=no dst-address=10.0.2.5
add action=accept comment=nodemcu disabled=no dst-address=10.0.3.5 \
    !dst-address-list !dst-port !protocol !src-address !src-address-list
add action=accept comment=telegram disabled=no dst-address=149.154.167.220 \
    !dst-address-list !dst-port !protocol !src-address !src-address-list
add action=accept comment=telegram disabled=no dst-address=149.154.167.41
add action=accept comment=telegram disabled=no dst-address=149.154.167.43
add action=accept comment=nodemcu disabled=no dst-address=10.0.0.4 \
    !src-address
/ip service
set telnet disabled=yes
set www disabled=yes
set api address=10.0.0.5/32,10.0.1.5/32,10.0.2.5/32,10.0.3.5/32
/system clock
set time-zone-name=Asia/Manila
/system identity
set name=mikrotik-haplite-lme
/system logging
add topics=firewall,hotspot,interface,system,dhcp,system,script
/system note
set note="lmepisowifi config v5.14"
/system ntp client
set enabled=yes primary-ntp=121.58.193.100 secondary-ntp=162.159.200.123
/system package update
set channel=long-term
/system scheduler
add interval=2m name="uptime backup" on-event=":local hsactiveuptime;\r\
    \n:local hsuser;\r\
    \n:local hslimit;\r\
    \n\r\
    \n:if ([/ip hotspot active print count-only] > 0) do={\r\
    \n:foreach i in=[/ip hotspot active find] do={\r\
    \n:set hsactiveuptime [/ip hotspot active get \$i uptime];\r\
    \n:set hsuser [/ip hotspot active get \$i user];\r\
    \n:set hslimit [/ip hotspot user get \$hsuser limit-uptime];\r\
    \n/system scheduler set [find where name=\$hsuser] comment=\"temp \$hsacti\
    veuptime\";\r\
    \n\t\t}\r\
    \n\t}\r\
    \n" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-time=startup
add name="uptime restore" on-event=":local ucom;\r\
    \n:local hsolduptime;\r\
    \n:local hsnewuptime;\r\
    \n:local hsactiveuptime;\r\
    \n:local hsuser;\r\
    \n:local temp; \r\
    \n:foreach ie in=[/sys sch find] do={\r\
    \n :set \$ucom [/sys sch get \$ie comment]; \r\
    \n:if (\$ucom != \"\") do={ \r\
    \n:set \$temp [:pick \$ucom 0 4];\r\
    \n:if (\$temp = \"temp\") do={\r\
    \n   :set \$hsuser [/sys sch get \$ie name]; \r\
    \n:if ([/ip hotspot user find name=\$hsuser]) do={\r\
    \n:set \$hsolduptime [/ip hotspot user get [find where name=\$hsuser] limi\
    t-uptime];\r\
    \n:set \$hsactiveuptime [:pick \$ucom 5 ([:len \$ucom] + 1)]; \r\
    \n:set \$hsnewuptime (hsolduptime - \$hsactiveuptime);\r\
    \n/ip hotspot user set [find where name=\$hsuser] limit-uptime=\$hsnewupti\
    me;\r\
    \n/sys sch set [find where name=\$hsuser] comment=\"\";} else={ /sys sch r\
    emove \$ie;}\r\
    \n}}}" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-time=startup
add interval=1h name="Reset Daily Income" on-event=":local sntpStatus [/system\
    \_ntp client get last-update-from];\
    \n:local currentDate [/system clock get date];\
    \n:local currentday [:pick \$currentDate 4 6];\
    \n:local iTBotToken [/system script get [find name=\"bottoken\"] source];\
    \n:local iTGrChatID [/system script get [find name=\"chatid\"] source];\
    \n:local todayIncomeSource [/system script get [find name=\"todayincome\"]\
    \_source];\
    \n\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    # Get scheduler comment\
    \n    :local schedulerComment [/system scheduler get [find name=\"Reset Da\
    ily Income\"] comment];\
    \n    \
    \n    :if (\$schedulerComment != \$currentday) do={\
    \n        # Only send message and reset if todayIncomeSource is not alread\
    y 0\
    \n        :if (\$todayIncomeSource != \"0\") do={\
    \n            :local message (\"The income today is: \" . \$todayIncomeSou\
    rce);\
    \n            /tool fetch url=(\"https://api.telegram.org/bot\" . \$iTBotT\
    oken . \"/sendMessage\?chat_id=\" . \$iTGrChatID . \"&text=\" . \$message)\
    \_keep-result=no;\
    \n            :delay 1s;\
    \n        }\
    \n        \
    \n        # Reset todayincome to 0\
    \n        /system script set source=\"0\" [find name=\"todayincome\"];\
    \n        \
    \n        # Update scheduler comment with current day\
    \n        /system scheduler set [find name=\"Reset Daily Income\"] comment\
    =\"\$currentday\";\
    \n        \
    \n        \
    \n    } else={\
    \n        \
    \n    }\
    \n} else={\
    \n    \
    \n}" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=sep/28/2021 start-time=00:00:01
add interval=15m name=maxactiveusers on-event=":local activeUsers [/ip hotspot\
    \_active print count-only];\
    \n:local currentSource [/system script get [find name=\"maxactiveusers\"] \
    source];\
    \n:local maxActiveUsers 0;\
    \n\
    \n# Extract the current maximum active users from the current source\
    \n:if ([:len \$currentSource] > 0) do={\
    \n    :set maxActiveUsers [:tonum \$currentSource];\
    \n}\
    \n\
    \n# Check if the current active users count exceeds the recorded maximum\
    \n:if (\$activeUsers > \$maxActiveUsers) do={\
    \n    # Update the source of the maxactiveusers script to the new maximum\
    \n    /system script set source=\"\$activeUsers\" [find name=\"maxactiveus\
    ers\"];\
    \n}" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-time=startup
add interval=1h name="reset maxactiveusers" on-event=":local sntpStatus [/syst\
    em ntp client get last-update-from];\
    \n\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    :local currentDate [/system clock get date];\
    \n    :local currentday [:pick \$currentDate 4 6];\
    \n    :local schedulerComment [/system scheduler get [find name=\"reset ma\
    xactiveusers\"] comment];\
    \n\
    \n    :if (\$schedulerComment != \$currentday) do={\
    \n        :local iTBotToken [/system script get [find name=\"bottoken\"] s\
    ource];\
    \n        :local iTGrChatID [/system script get [find name=\"chatid\"] sou\
    rce];\
    \n        :local maxActiveUsersSource [/system script get [find name=\"max\
    activeusers\"] source];\
    \n\
    \n        :if (\$maxActiveUsersSource != \"0\") do={\
    \n            :local message (\"The top active users for today is: \" . \$\
    maxActiveUsersSource);\
    \n            /tool fetch url=(\"https://api.telegram.org/bot\" . \$iTBotT\
    oken . \"/sendMessage\?chat_id=\" . \$iTGrChatID . \"&text=\" . \$message)\
    \_keep-result=no;\
    \n            :delay 1s;\
    \n        }\
    \n\
    \n        /system script set source=\"0\" [find name=\"maxactiveusers\"];\
    \n        /system scheduler set [find name=\"reset maxactiveusers\"] comme\
    nt=\"\$currentday\";\
    \n    }\
    \n}" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=feb/16/2025 start-time=00:00:01
add interval=1h name=resetmonthly on-event=":local sntpStatus [/system ntp cli\
    ent get last-update-from];\
    \n\
    \n# Check if SNTP is synced first\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    :local currentDate [/system clock get date];\
    \n    :local currentMonth [:pick \$currentDate 0 3];\
    \n    :local script [/system script find name=\"currentmonth\"];\
    \n\
    \n    # Check if the script exists\
    \n    :if ([:len \$script] > 0) do={\
    \n        # Get the current source of the script\
    \n        :local existingSource [/system script get \$script source];\
    \n\
    \n        # Extract the month from the existing source\
    \n        :local existingMonth [:pick \$existingSource 0 3];  # Assuming t\
    he month is stored as \"jan\", \"feb\", etc.\
    \n\
    \n        # Compare the existing month with the current month\
    \n        :if (\$existingMonth != \$currentMonth) do={\
    \n            # Update the script's source if the months are different\
    \n            /system script set \$script source=\"\$currentMonth\";\
    \n            \
    \n            # Define the Telegram bot token and chat ID\
    \n            :local iTBotToken [/system script get [find name=\"bottoken\
    \"] source];\
    \n            :local iTGrChatID [/system script get [find name=\"chatid\"]\
    \_source];\
    \n            :local monthlyIncomeSource [/system script get [find name=\"\
    monthlyincome\"] source];\
    \n            \
    \n            # Only send message if monthly income is not already 0\
    \n            :if (\$monthlyIncomeSource != \"0\") do={\
    \n                :local message (\"The income for this month is: \" . \$m\
    onthlyIncomeSource);\
    \n                /tool fetch url=(\"https://api.telegram.org/bot\" . \$iT\
    BotToken . \"/sendMessage\?chat_id=\" . \$iTGrChatID . \"&text=\" . \$mess\
    age) keep-result=no;\
    \n                :delay 1s;\
    \n            }\
    \n            \
    \n            # Reset monthly income to 0\
    \n            /system script set source=\"0\" [find name=\"monthlyincome\"\
    ];\
    \n            \
    \n            \
    \n        } else={\
    \n            \
    \n        }\
    \n    } else={\
    \n        \
    \n    }\
    \n} else={\
    \n    \
    \n}" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=mar/24/2025 start-time=00:00:00
add disabled=yes interval=1d name=autonightlighton on-event="/tool fetch http-\
    method=post http-header-field=\"X-TOKEN: t2iucb6jb4\" url=\"http://10.0.0.\
    5/admin/api/toggerNightLight\?toggle=1\"" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=may/15/2025 start-time=18:00:00
add disabled=yes interval=1d name=autonightlightoff on-event="/tool fetch http\
    -method=post http-header-field=\"X-TOKEN: t2iucb6jb4\" url=\"http://10.0.0\
    .5/admin/api/toggerNightLight\?toggle=0\"" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=may/15/2025 start-time=23:30:00
add interval=1d name=autorestart on-event="/system reboot" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jun/11/2025 start-time=03:00:00
add disabled=yes interval=5s name="check data file" on-event=":foreach u in=[/\
    ip hotspot user find] do={  \
    \n    :local uname [/ip hotspot user get \$u name]  \
    \n    :local fname (\"hotspot/data/\" . \$uname . \".txt\")  \
    \n\
    \n    :if ([:len \$uname] = 12) do={  \
    \n        # check if file exists directly  \
    \n        :local fId [/file find where name=\$fname]  \
    \n        :local content \$uname  \
    \n\
    \n        # check if scheduler with same name exists  \
    \n        :local schedId [/system scheduler find where name=\$uname]  \
    \n        :if ([:len \$schedId] > 0) do={  \
    \n            :local nextrun [/system scheduler get \$schedId next-run]  \
    \n            :set content (\$content . \"#\" . \$nextrun)  \
    \n        }  \
    \n\
    \n        # if file doesn\E2\80\99t exist, create it  \
    \n        :if ([:len \$fId] = 0) do={  \
    \n            /file print file=\$fname where name=\"\"  \
    \n            :delay 1s  \
    \n            :set fId [/file find where name=\$fname]  \
    \n        } else={  \
    \n            :set fId [:pick \$fId 0] ;# pick first ID if multiple (safet\
    y)  \
    \n        }  \
    \n\
    \n        # always update contents (avoids stale data)  \
    \n        /file set \$fId contents=\$content  \
    \n    }  \
    \n\
    \n    # add delay here to reduce load per iteration  \
    \n    :delay 200ms\
    \n}" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-time=startup
add name="create scripts & disable packages" on-event="/system script add name\
    =\"todayincome\" source=\"0\"\
    \n\
    \n/system script add name=\"yearlyincome\" source=\"0\"\
    \n\
    \n/system script add name=\"chatid\" source=\"chatid\"\
    \n\
    \n/system script add name=\"bottoken\" source=\"bottoken\"\
    \n\
    \n/system script add name=\"monthlyincome\" source=\"0\"\
    \n\
    \n/system script add name=\"maxactiveusers\" source=\"0\"\
    \n\
    \n:local currentDate [/system clock get date];\
    \n\
    \n# Extract the current month index (first three letters of the month)\
    \n:local currentMonth [:pick \$currentDate 0 3];\
    \n\
    \n:delay 1s\
    \n\
    \n/system script add name=\"currentmonth\" source=\"\$currentMonth\"\
    \n\
    \n:delay 1s\
    \n\
    \n# ============================================================\
    \n# update_binding.rsc\
    \n# Reads MAC from the \"nodemcumac\" system script, then updates\
    \n# the IP binding for 10.0.0.5 with that MAC, enables it,\
    \n# and flushes active firewall connections.\
    \n# ============================================================\
    \n\
    \n# --- 1. Pull MAC from the \"nodemcumac\" script source field ---\
    \n:local newMac [/system script get \"nodemcumac\" source]\
    \n\
    \n# Strip any trailing whitespace / newline characters\
    \n:set newMac [:pick \$newMac 0 [:len \$newMac]]\
    \n\
    \n:log info \"update_binding: retrieved MAC -> \$newMac\"\
    \n\
    \n# --- 2. Validate that we actually got something ---\
    \n:if ([:len \$newMac] = 0) do={\
    \n    :log error \"update_binding: MAC address is empty, aborting.\"\
    \n    :error \"MAC address retrieved from nodemcumac is empty.\"\
    \n}\
    \n\
    \n# --- 3. Check for an IP binding entry at 10.0.0.5 ---\
    \n:local bindingId [/ip dhcp-server lease find where address=\"10.0.0.5\" \
    type=static]\
    \n\
    \n:if ([:len \$bindingId] > 0) do={\
    \n\
    \n    :log info \"update_binding: found static binding for 10.0.0.5, updat\
    ing...\"\
    \n\
    \n    # Replace MAC address, ensure the binding is enabled\
    \n    /ip dhcp-server lease set \$bindingId \\\
    \n        mac-address=\$newMac \\\
    \n        disabled=no\
    \n\
    \n    :log info \"update_binding: binding updated and enabled.\"\
    \n\
    \n} else={\
    \n    :log warning \"update_binding: no static binding found for 10.0.0.5,\
    \_skipping update.\"\
    \n}\
    \n\
    \n# --- 4. Flush all active firewall connections ---\
    \n:log info \"update_binding: flushing firewall connection table...\"\
    \n/ip firewall connection remove [find]\
    \n:log info \"update_binding: connection table flushed.\"\
    \n\
    \n:delay 1s\
    \n\
    \n/system script run rebootmikrotik" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-time=startup
add interval=1h name="reset yearly" on-event=":local sntpStatus [/system ntp c\
    lient get last-update-from];\
    \n:local currentDate [/system clock get date];\
    \n:local currentyear [:pick \$currentDate 7 11];\
    \n:local iTBotToken [/system script get [find name=\"bottoken\"] source];\
    \n:local iTGrChatID [/system script get [find name=\"chatid\"] source];\
    \n:local yearlyIncomeSource [/system script get [find name=\"yearlyincome\
    \"] source];\
    \n\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    # Get scheduler comment\
    \n    :local schedulerComment [/system scheduler get [find name=\"reset ye\
    arly\"] comment];\
    \n    \
    \n    :if (\$schedulerComment != \$currentyear) do={\
    \n        :if (\$yearlyIncomeSource != \"0\") do={\
    \n            :local message (\"The income for this year is: \" . \$yearly\
    IncomeSource);\
    \n            /tool fetch url=(\"https://api.telegram.org/bot\" . \$iTBotT\
    oken . \"/sendMessage\?chat_id=\" . \$iTGrChatID . \"&text=\" . \$message)\
    \_keep-result=no;\
    \n            :delay 1s;\
    \n        }\
    \n        \
    \n        \
    \n        /system script set source=\"0\" [find name=\"yearlyincome\"];\
    \n        \
    \n        \
    \n        /system scheduler set [find name=\"reset yearly\"] comment=\"\$c\
    urrentyear\";\
    \n        \
    \n        \
    \n    } else={\
    \n        \
    \n    }\
    \n} else={\
    \n    \
    \n}" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jan/02/1970 start-time=00:00:01
/system script
add comment=rebootmikrotik dont-require-permissions=no name=rebootmikrotik \
    owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    delay 1s\
    \n\
    \n/system scheduler remove [find name=\"create scripts & disable packages\
    \"]\
    \n/system script remove nodemcumac\
    \n\
    \n/system reboot"
add comment="input nodemcu mac before rebooting" dont-require-permissions=no \
    name=nodemcumac owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=\
    ""
