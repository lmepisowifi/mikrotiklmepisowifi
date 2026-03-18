# Get User Data
:local date [ /system clock get date]
:local time [ /system clock get time]

:local aUsrNote [/ip hotspot user get $user comment];
:local aUsrNote [:toarray $aUsrNote];
:local iSaleAmt [:tonum ($aUsrNote->1)];
:local totaltime [/ip hotspot user get [find name=$user] limit-uptime];
:local cpuusage [/system resource get cpu-load];
:local freeRam [/system resource get free-memory];
:local ramMB ($freeRam / 1048576);
:local ramdecimal ($ramMB % 10);

:local queueName "PCQ simple queue";
:local queueRate "0kbps/0kbps";

:do {
    :local qData [/queue simple print stats as-value where name=$queueName];
    :if ([:len $qData] > 0) do={
        :set queueRate ([:pick $qData 0]->"rate");
    }
} on-error={}

:local limit 0s;
:local uptime 0s;
:local remainingt 0s;
:local totaluptime 0s;
:local mac $"mac-address";
:local macNoCol ("$[:pick $mac 0 2]$[:pick $mac 3 5]$[:pick $mac 6 8]$[:pick $mac 9 11]$[:pick $mac 12 14]$[:pick $mac 15 17]");
 # Get Device Name (Optimized trimming)
:local deviceName [/ip dhcp-server lease get [find mac-address=$mac] host-name];
:if ([:len $deviceName] = 0) do={ :set deviceName "N/A"; }
	
:do {
    :set limit [/ip hotspot user get [find name=$user] limit-uptime];
    :set uptime [/ip hotspot user get [find name=$user] uptime];
    :set remainingt ($limit - $uptime);
    :set totaluptime ($limit - $remainingt);
} on-error={ 
    :log warning "time variable error!";
};


### enable telegram notification, change from 0 to 1 if you want to enable telegram
:local isTelegram [:tonum [/system script get [find name="enabletelegram"] source]];
:local iTBotToken [/system script get [find name="bottoken"] source];
:local iTGrChatID [/system script get [find name="chatid"] source];
### hotspot folder for HEX put flash/hotspot for haplite put hotspot only
:local HSFilePath "hotspot";
:local uactive [/ip hotspot active print count-only];

### enable discord notification, change from 0 to 1 to enable
:local isDiscord [:tonum [/system script get [find name="enablediscord"] source]];
:local iDiscordWebhook [/system script get [find name="discordwebhook"] source];

:local todaysales [:tonum [/system script get todayincome source]];
:local mnthlysales [:tonum [/system script get monthlyincome source]];
:local yearlysales [:tonum [/system script get yearlyincome source]];



:local iDailySales ($iSaleAmt + $todaysales);
/system script set todayincome source="$iDailySales";
:local iMonthSales ($iSaleAmt + $mnthlysales);
/system script set monthlyincome source="$iMonthSales";
:local iYearSales ($iSaleAmt + $yearlysales);
/system script set yearlyincome source="$iYearSales";

:local hotspotFolder "hotspot";
:local com [/ip hotspot user get [find name=$user] comment];
:if ($com="") do={
:local rtimeMessage ("$user%20resumed%20time,%20remaining%20time%20is%20$remainingt%0AActive%20Users:%20$uactive");
:if ($isTelegram=1) do={
    /tool fetch url="https://api.telegram.org/bot$iTBotToken/sendMessage?chat_id=$iTGrChatID&text=$rtimeMessage" keep-result=no;
}
if ($isDiscord=1) do={
    /tool fetch url=$iDiscordWebhook http-method=post http-data=("content=" . "```$rtimeMessage```%0A** **") mode=https keep-result=no
}
    
}
/ip hotspot user set comment="" $user;
:if ($com!="") do={
	:local validity [:pick $com 0 [:find $com ","]];
	:if ( $validity!="0m" ) do={
		:local sc [/sys scheduler find name=$user]; :if ($sc="") do={ :local a [/ip hotspot user get [find name=$user] limit-uptime]; :local c ($validity); :local date [ /system clock get date]; /sys sch add name="$user" disable=no start-date=$date interval=$c on-event="/ip hotspot user remove [find name=$user]; /ip hotspot active remove [find user=$user]; /ip hotspot cookie remove [find user=$user]; /system sche remove [find name=$user]; /file remove \"$hotspotFolder/data/$macNoCol.txt\";" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon; :delay 2s; } else={ :local sint [/sys scheduler get $user interval]; :if ( $validity!="" ) do={ /sys scheduler set $user interval ($sint+$validity); } };
	}

	:local fileScheduler "FILE$macNoCol";
	:local fsc [/sys scheduler find name=$fileScheduler];
	:local validUntil [/sys scheduler get $user next-run];
	:if ($fsc!="") do={
		/system scheduler remove [find name=$fileScheduler];
	}
	:do { /system scheduler add name="$fileScheduler" interval=5 \
			start-date=[/system clock get date] start-time=[/system clock get time] disable=no \
			policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
			on-event=("/system scheduler set $fileScheduler interval 0;\r\n".\
						"/file print file=\"$hotspotFolder/data/$macNoCol\" where name=\"dummyfile\";\r\n".\
						":delay 1s;\r\n".\
						"/file set \"$hotspotFolder/data/$macNoCol\" contents=\"$user#$validUntil\";\r\n".\
						":log warning \"juanfimonitoring.com ==> parallel script executed successfully.\";\r\n")
		} on-error={ :log error "juanfimonitoring.com ==> parallel script creation error."; };
:local currentday [:pick $date 4 6]
:local estimatedperday ($mnthlysales / $currentday)
:local estimatedpermonth ($estimatedperday * 30)
:local iValidUntil [/system scheduler get $user next-run];
:local loginMessage ("Information:%0ACoin:%20₱%20$iSaleAmt%0AUser:%20$user%0ADevice%20Name:%20$deviceName%0ATotal%20Time:%20$totaltime%0AUsed%20Time:%20$totaluptime%0ARemaining%20Time:%20$remainingt%0AExpires%20On:%20$iValidUntil%0A%0ACurrent:%0AToday%20Sales:%20₱%20$iDailySales%0AIncome%20This%20Month:%20₱%20$iMonthSales%0AIncome%20This%20Year:%20$iYearSales%0AActive%20Users:%20$uactive%0A%0ASystem%20Information:%0ACPU%20Usage:%20$cpuusage%25%0ARemaining%20Memory:%20$ramMB.$ramdecimal%20MB%0ACurrent%20Throughput:%20$queueRate%0A%0AEstimates:%0AEstimated%20Per%20Day:%20₱%20$estimatedperday%0AEstimated%20Per%20Month:%20₱%20$estimatedpermonth%0A%0A(Note:%20The%20Estimates%20are%20not%20the%20current%20sales.)%0A%0ADate%20%26%20Timestamp:%20$date%20$time");
    :if ($isTelegram=1) do={
    /tool fetch url="https://api.telegram.org/bot$iTBotToken/sendMessage?chat_id=$iTGrChatID&text=$loginMessage" keep-result=no;
    }
    :if ($isDiscord=1) do={
    /tool fetch url=$iDiscordWebhook http-method=post http-data=("content=" . "```$loginMessage```%0A** **") mode=https keep-result=no
    }
}

:local cmac $"mac-address"
:foreach AU in=[/ip hotspot active find user="$username"] do={
	:local amac [/ip hotspot active get $AU mac-address];
	:if ($cmac!=$amac) do={  /ip hotspot active remove [/ip hotspot active find mac-address="$amac"]; }
}


