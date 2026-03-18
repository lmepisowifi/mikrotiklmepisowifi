:local com [/ip hotspot user get [find name=$user] comment];
:local hotspotFolder "hotspot";
:local mac $"mac-address";
:local macNoCol;
:for i from=0 to=([:len $mac] - 1) do={ 
  :local char [:pick $mac $i]
  :if ($char = ":") do={
	:set $char ""
  }
  :set macNoCol ($macNoCol . $char)
}
:if ([/ip hotspot user get [/ip hotspot user find where name="$user"] limit-uptime] <= [/ip hotspot user get [/ip hotspot user find where name="$user"] uptime]) do={
    /ip hotspot user remove $user;
	/file remove "$hotspotFolder/data/$macNoCol.txt";
	/system sche remove [find name=$user];
}

:local fileScheduler "FILE$macNoCol";
:local fsc [/sys scheduler find name=$fileScheduler];
:if ($fsc!="") do={
	/system scheduler remove [find name=$fileScheduler];
}
:local retryScheduler "RETRY$macNoCol"
:local fsc [/sys scheduler find name=retryScheduler];
:if ($fsc!="") do={
	/system scheduler remove [find name=retryScheduler];
}
### enable telegram notification, change from 0 to 1 if you want to enable telegram
:local isTelegram [:tonum [/system script get [find name="enabletelegram"] source]];
### enable discord notification, change from 0 to 1 to enable
:local isDiscord [:tonum [/system script get [find name="enablediscord"] source]];
:local iDiscordWebhook [/system script get [find name="discordwebhook"] source];

:local iTBotToken [/system script get [find name="bottoken"] source];
:local iTGrChatID [/system script get [find name="chatid"] source];
# Check for session timeout and send notification
:if ($cause="session timeout") do={
:local timeoutMessage ("$user ran out of time!");
:if ($isTelegram=1) do={
/tool fetch url="https://api.telegram.org/bot$iTBotToken/sendMessage?chat_id=$iTGrChatID&text=$timeoutMessage" keep-result=no;
}
:if ($isDiscord=1) do={
/tool fetch url=$iDiscordWebhook http-method=post http-data=("content=" . "```$timeoutmessage```%0A** **") mode=https keep-result=no
}
}

:if ($com="") do={
:if ($cause="user request") do={
:local pauseMessage ("$user paused time.");
:if ($isTelegram=1) do={  
  /tool fetch url="https://api.telegram.org/bot$iTBotToken/sendMessage?chat_id=$iTGrChatID&text=$pauseMessage" keep-result=no;
}
:if ($isDiscord=1) do={
/tool fetch url=$iDiscordWebhook http-method=post http-data=("content=" . "```$pauseMessage```%0A** **") mode=https keep-result=no
}
}
}



:if ($cause="keepalive timeout") do={
:local timeoutMessage ("automatically paused time for $user");
:if ($isTelegram=1) do={
/tool fetch url="https://api.telegram.org/bot$iTBotToken/sendMessage?chat_id=$iTGrChatID&text=$timeoutMessage" keep-result=no;
}
:if ($isDiscord=1) do={
/tool fetch url=$iDiscordWebhook http-method=post http-data=("content=" . "```$timeoutMessage```%0A** **") mode=https keep-result=no
}
}

:if ($cause="admin reset") do={ 
  :local kickMessage ("admin kicked $user");
:if ($isTelegram=1) do={
/tool fetch url="https://api.telegram.org/bot$iTBotToken/sendMessage?chat_id=$iTGrChatID&text=$kickMessage" keep-result=no;
}
:if ($isDiscord=1) do={
/tool fetch url=$iDiscordWebhook http-method=post http-data=("content=" . "```$kickMessage```%0A** **") mode=https keep-result=no
}
}

:local iValidUntil [/system scheduler get $user next-run];

:if ([:len [/ip hotspot user find where name=$user]] > 0) do={
    :if ([:len [/file find name="hotspot/data/$user.txt"]] = 0) do={
        :local myfile "hotspot/data/$user.txt";
        /file print file=$myfile;
        :delay 0;
        :local cont "$user#$iValidUntil";
        /file set $myfile contents=$cont;
    }
}
