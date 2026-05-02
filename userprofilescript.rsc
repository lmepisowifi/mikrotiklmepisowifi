:foreach sName in={"enabletelegram";"bottoken";"chatid";"enablediscord";"discordwebhook";"todayincome";"monthlyincome";"yearlyincome";"maxactiveusers";"cachedrates"} do={
    :if ([:len [/system script find name=$sName]] = 0) do={
        :if ($sName = "cachedrates") do={
            /system script add name=$sName source="" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon;
        } else={
            /system script add name=$sName source="0" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon;
        }
        :log warning "Created missing script: $sName";
    }
}

/system ntp client
set enabled=yes primary-ntp=[:resolve ntp.pagasa.dost.gov.ph] secondary-ntp=[:resolve 0.asia.pool.ntp.org]

/system scheduler

# --- uptime backup ---
:if ([/system scheduler find name="uptime backup"] = "") do={
    /system scheduler add \
        interval=5m \
        name="uptime backup" \
        on-event=":local hsactiveuptime;\
    \n:local hsuser;\
    \n\
    \n:if ([/ip hotspot active print count-only] > 0) do={\
    \n    :foreach i in=[/ip hotspot active find] do={\
    \n        :set hsactiveuptime [/ip hotspot active get \$i uptime];\
    \n        :set hsuser [/ip hotspot active get \$i user];\
    \n        /system scheduler set [find where name=\$hsuser] comment=\"temp \$hsactiveuptime\";\
    \n    }\
    \n}" \
        policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
        start-time=startup
} else={
    /system scheduler set [find name="uptime backup"] \
        interval=5m \
        on-event=":local hsactiveuptime;\
    \n:local hsuser;\
    \n\
    \n:if ([/ip hotspot active print count-only] > 0) do={\
    \n    :foreach i in=[/ip hotspot active find] do={\
    \n        :set hsactiveuptime [/ip hotspot active get \$i uptime];\
    \n        :set hsuser [/ip hotspot active get \$i user];\
    \n        /system scheduler set [find where name=\$hsuser] comment=\"temp \$hsactiveuptime\";\
    \n    }\
    \n}" \
        policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
        start-time=startup
}

# --- uptime restore ---
:if ([/system scheduler find name="uptime restore"] = "") do={
    /system scheduler add \
        name="uptime restore" \
        on-event=":local ucom;\
    \n:local hsolduptime;\
    \n:local hsnewuptime;\
    \n:local hsactiveuptime;\
    \n:local hsuser;\
    \n:local temp;\
    \n:foreach ie in=[/sys sch find] do={\
    \n    :set \$ucom [/sys sch get \$ie comment];\
    \n    :if (\$ucom != \"\") do={\
    \n        :set \$temp [:pick \$ucom 0 4];\
    \n        :if (\$temp = \"temp\") do={\
    \n            :set \$hsuser [/sys sch get \$ie name];\
    \n            :if ([/ip hotspot user find name=\$hsuser]) do={\
    \n                :set \$hsolduptime [/ip hotspot user get [find where name=\$hsuser] limit-uptime];\
    \n                :set \$hsactiveuptime [:pick \$ucom 5 [:len \$ucom]];\
    \n                :set \$hsnewuptime (\$hsolduptime - \$hsactiveuptime);\
    \n                /ip hotspot user set [find where name=\$hsuser] limit-uptime=\$hsnewuptime;\
    \n                /sys sch set [find where name=\$hsuser] comment=\"\";\
    \n            } else={\
    \n                /sys sch remove \$ie;\
    \n            }\
    \n        }\
    \n    }\
    \n}" \
        policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
        start-time=startup
} else={
    /system scheduler set [find name="uptime restore"] \
        on-event=":local ucom;\
    \n:local hsolduptime;\
    \n:local hsnewuptime;\
    \n:local hsactiveuptime;\
    \n:local hsuser;\
    \n:local temp;\
    \n:foreach ie in=[/sys sch find] do={\
    \n    :set \$ucom [/sys sch get \$ie comment];\
    \n    :if (\$ucom != \"\") do={\
    \n        :set \$temp [:pick \$ucom 0 4];\
    \n        :if (\$temp = \"temp\") do={\
    \n            :set \$hsuser [/sys sch get \$ie name];\
    \n            :if ([/ip hotspot user find name=\$hsuser]) do={\
    \n                :set \$hsolduptime [/ip hotspot user get [find where name=\$hsuser] limit-uptime];\
    \n                :set \$hsactiveuptime [:pick \$ucom 5 [:len \$ucom]];\
    \n                :set \$hsnewuptime (\$hsolduptime - \$hsactiveuptime);\
    \n                /ip hotspot user set [find where name=\$hsuser] limit-uptime=\$hsnewuptime;\
    \n                /sys sch set [find where name=\$hsuser] comment=\"\";\
    \n            } else={\
    \n                /sys sch remove \$ie;\
    \n            }\
    \n        }\
    \n    }\
    \n}" \
        policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
        start-time=startup
}

# --- Reset Daily Income ---
:if ([/system scheduler find name="Reset Daily Income"] = "") do={
    /system scheduler add \
        interval=1h \
        name="Reset Daily Income" \
        on-event=":local sntpStatus [/system ntp client get last-update-from];\
    \n:local currentDate [/system clock get date];\
    \n:local currentday [:pick \$currentDate 4 6];\
    \n:local iTBotToken [/system script get [find name=\"bottoken\"] source];\
    \n:local iTGrChatID [/system script get [find name=\"chatid\"] source];\
    \n:local isTelegram [:tonum [/system script get [find name=\"enabletelegram\"] source]];\
    \n\
    \n:local isDiscord [:tonum [/system script get [find name=\"enablediscord\"] source]];\
    \n:local iDiscordWebhook [/system script get [find name=\"discordwebhook\"] source];\
    \n\
    \n:local todayIncomeSource [/system script get [find name=\"todayincome\"] source];\
    \n\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    # Get scheduler comment\
    \n    :local schedulerComment [/system scheduler get [find name=\"Reset Daily Income\"] comment];\
    \n    \
    \n    :if (\$schedulerComment != \$currentday) do={\
    \n        # Only send message and reset if todayIncomeSource is not already 0\
    \n        :if (\$todayIncomeSource != \"0\") do={\
    \n            :local message (\"The income today is: \" . \$todayIncomeSource);\
    \n            :if (\$isTelegram=1) do={\
    \n            /tool fetch url=(\"https://api.telegram.org/bot\" . \$iTBotToken . \"/sendMessage\?chat_id=\" . \$iTGrChatID . \"&text=\" . \$message) keep-result=no;\
    \n            }\
    \n            :delay 1s;\
    \n            :if (\$isDiscord=1) do={\
    \n            /tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"content=\" . \"```\$message```%0A** **\") mode=https keep-result=no\
    \n            }\
    \n        }\
    \n        \
    \n        # Reset todayincome to 0\
    \n        /system script set source=\"0\" [find name=\"todayincome\"];\
    \n        \
    \n        # Update scheduler comment with current day\
    \n        /system scheduler set [find name=\"Reset Daily Income\"] comment=\"\$currentday\";\
    \n        \
    \n    } else={\
    \n        \
    \n    }\
    \n} else={\
    \n    \
    \n}" \
        policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
        start-date=sep/28/2021 \
        start-time=00:00:01
} else={
    /system scheduler set [find name="Reset Daily Income"] \
        interval=1h \
        on-event=":local sntpStatus [/system ntp client get last-update-from];\
    \n:local currentDate [/system clock get date];\
    \n:local currentday [:pick \$currentDate 4 6];\
    \n:local iTBotToken [/system script get [find name=\"bottoken\"] source];\
    \n:local iTGrChatID [/system script get [find name=\"chatid\"] source];\
    \n:local isTelegram [:tonum [/system script get [find name=\"enabletelegram\"] source]];\
    \n\
    \n:local isDiscord [:tonum [/system script get [find name=\"enablediscord\"] source]];\
    \n:local iDiscordWebhook [/system script get [find name=\"discordwebhook\"] source];\
    \n\
    \n:local todayIncomeSource [/system script get [find name=\"todayincome\"] source];\
    \n\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    # Get scheduler comment\
    \n    :local schedulerComment [/system scheduler get [find name=\"Reset Daily Income\"] comment];\
    \n    \
    \n    :if (\$schedulerComment != \$currentday) do={\
    \n        # Only send message and reset if todayIncomeSource is not already 0\
    \n        :if (\$todayIncomeSource != \"0\") do={\
    \n            :local message (\"The income today is: \" . \$todayIncomeSource);\
    \n            :if (\$isTelegram=1) do={\
    \n            /tool fetch url=(\"https://api.telegram.org/bot\" . \$iTBotToken . \"/sendMessage\?chat_id=\" . \$iTGrChatID . \"&text=\" . \$message) keep-result=no;\
    \n            }\
    \n            :delay 1s;\
    \n            :if (\$isDiscord=1) do={\
    \n            /tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"content=\" . \"```\$message```%0A** **\") mode=https keep-result=no\
    \n            }\
    \n        }\
    \n        \
    \n        # Reset todayincome to 0\
    \n        /system script set source=\"0\" [find name=\"todayincome\"];\
    \n        \
    \n        # Update scheduler comment with current day\
    \n        /system scheduler set [find name=\"Reset Daily Income\"] comment=\"\$currentday\";\
    \n        \
    \n    } else={\
    \n        \
    \n    }\
    \n} else={\
    \n    \
    \n}" \
        policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon
}

# --- reset maxactiveusers ---
:if ([/system scheduler find name="reset maxactiveusers"] = "") do={
    /system scheduler add \
        interval=1h \
        name="reset maxactiveusers" \
        on-event=":local sntpStatus [/system ntp client get last-update-from];\
    \n\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    :local currentDate [/system clock get date];\
    \n    :local currentday [:pick \$currentDate 4 6];\
    \n    :local schedulerComment [/system scheduler get [find name=\"reset maxactiveusers\"] comment];\
    \n\
    \n    :if (\$schedulerComment != \$currentday) do={\
    \n        :local iTBotToken [/system script get [find name=\"bottoken\"] source];\
    \n        :local iTGrChatID [/system script get [find name=\"chatid\"] source];\
    \n        :local rstschedulerEntry [/system scheduler find name=\"reset maxactiveusers\"];\
    \n        :local currentSource [/system script get [find name=\"maxactiveusers\"] source];\
    \n        :local isTelegram [:tonum [/system script get [find name=\"enabletelegram\"] source]];\
    \n\
    \n        :local isDiscord [:tonum [/system script get [find name=\"enablediscord\"] source]];\
    \n        :local iDiscordWebhook [/system script get [find name=\"discordwebhook\"] source];\
    \n\
    \n        :if (\$currentSource != \"0\") do={\
    \n            :local message (\"The top active users for today is: \" . \$currentSource);\
    \n            :if (\$isDiscord=1) do={\
    \n                /tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"content=\" . \"```\$message```%0A** **\") mode=https keep-result=no\
    \n            }\
    \n            :if (\$isTelegram=1) do={\
    \n                /tool fetch url=(\"https://api.telegram.org/bot\" . \$iTBotToken . \"/sendMessage\?chat_id=\" . \$iTGrChatID . \"&text=\" . \$message) keep-result=no;\
    \n            }\
    \n            :delay 1s;\
    \n        }\
    \n\
    \n        /system script set [find name=\"maxactiveusers\"] source=\"0\";\
    \n        /system scheduler set \$rstschedulerEntry comment=\"\$currentday\";\
    \n    }\
    \n}" \
        policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
        start-date=feb/16/2025 \
        start-time=00:00:01
} else={
    /system scheduler set [find name="reset maxactiveusers"] \
        interval=1h \
        on-event=":local sntpStatus [/system ntp client get last-update-from];\
    \n\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    :local currentDate [/system clock get date];\
    \n    :local currentday [:pick \$currentDate 4 6];\
    \n    :local schedulerComment [/system scheduler get [find name=\"reset maxactiveusers\"] comment];\
    \n\
    \n    :if (\$schedulerComment != \$currentday) do={\
    \n        :local iTBotToken [/system script get [find name=\"bottoken\"] source];\
    \n        :local iTGrChatID [/system script get [find name=\"chatid\"] source];\
    \n        :local rstschedulerEntry [/system scheduler find name=\"reset maxactiveusers\"];\
    \n        :local currentSource [/system script get [find name=\"maxactiveusers\"] source];\
    \n        :local isTelegram [:tonum [/system script get [find name=\"enabletelegram\"] source]];\
    \n\
    \n        :local isDiscord [:tonum [/system script get [find name=\"enablediscord\"] source]];\
    \n        :local iDiscordWebhook [/system script get [find name=\"discordwebhook\"] source];\
    \n\
    \n        :if (\$currentSource != \"0\") do={\
    \n            :local message (\"The top active users for today is: \" . \$currentSource);\
    \n            :if (\$isDiscord=1) do={\
    \n                /tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"content=\" . \"```\$message```%0A** **\") mode=https keep-result=no\
    \n            }\
    \n            :if (\$isTelegram=1) do={\
    \n                /tool fetch url=(\"https://api.telegram.org/bot\" . \$iTBotToken . \"/sendMessage\?chat_id=\" . \$iTGrChatID . \"&text=\" . \$message) keep-result=no;\
    \n            }\
    \n            :delay 1s;\
    \n        }\
    \n\
    \n        /system script set [find name=\"maxactiveusers\"] source=\"0\";\
    \n        /system scheduler set \$rstschedulerEntry comment=\"\$currentday\";\
    \n    }\
    \n}" \
        policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon
}

# --- resetmonthly ---
:if ([/system scheduler find name="resetmonthly"] = "") do={
    /system scheduler add \
        interval=1h \
        name="resetmonthly" \
        on-event=":local sntpStatus [/system ntp client get last-update-from];\
    \n:local isTelegram [:tonum [/system script get [find name=\"enabletelegram\"] source]];\
    \n:local isDiscord [:tonum [/system script get [find name=\"enablediscord\"] source]];\
    \n:local iDiscordWebhook [/system script get [find name=\"discordwebhook\"] source];\
    \n\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    :local currentDate [/system clock get date];\
    \n    :local currentMonth [:pick \$currentDate 0 3];\
    \n\
    \n    # Read the stored month from this scheduler's own comment\
    \n    :local schedulerEntry [/system scheduler find name=\"resetmonthly\"];\
    \n    :local storedMonth [/system scheduler get \$schedulerEntry comment];\
    \n\
    \n    :if (\$storedMonth != \$currentMonth) do={\
    \n        # Update the comment to the new month\
    \n        /system scheduler set \$schedulerEntry comment=\"\$currentMonth\";\
    \n\
    \n        :local iTBotToken [/system script get [find name=\"bottoken\"] source];\
    \n        :local iTGrChatID [/system script get [find name=\"chatid\"] source];\
    \n        :local monthlyIncomeSource [/system script get [find name=\"monthlyincome\"] source];\
    \n\
    \n        :if (\$monthlyIncomeSource != \"0\") do={\
    \n            :local message (\"The income for this month is: \" . \$monthlyIncomeSource);\
    \n            :if (\$isTelegram=1) do={\
    \n                /tool fetch url=(\"https://api.telegram.org/bot\" . \$iTBotToken . \"/sendMessage\?chat_id=\" . \$iTGrChatID . \"&text=\" . \$message) keep-result=no;\
    \n            }\
    \n            :if (\$isDiscord=1) do={\
    \n                /tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"content=\" . \"```\$message```%0A** **\") mode=https keep-result=no;\
    \n            }\
    \n            :delay 1s;\
    \n        }\
    \n\
    \n        /system script set source=\"0\" [find name=\"monthlyincome\"];\
    \n    }\
    \n}" \
        policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
        start-date=mar/24/2025 \
        start-time=00:00:01
} else={
    /system scheduler set [find name="resetmonthly"] \
        interval=1h \
        on-event=":local sntpStatus [/system ntp client get last-update-from];\
    \n:local isTelegram [:tonum [/system script get [find name=\"enabletelegram\"] source]];\
    \n:local isDiscord [:tonum [/system script get [find name=\"enablediscord\"] source]];\
    \n:local iDiscordWebhook [/system script get [find name=\"discordwebhook\"] source];\
    \n\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    :local currentDate [/system clock get date];\
    \n    :local currentMonth [:pick \$currentDate 0 3];\
    \n\
    \n    # Read the stored month from this scheduler's own comment\
    \n    :local schedulerEntry [/system scheduler find name=\"resetmonthly\"];\
    \n    :local storedMonth [/system scheduler get \$schedulerEntry comment];\
    \n\
    \n    :if (\$storedMonth != \$currentMonth) do={\
    \n        # Update the comment to the new month\
    \n        /system scheduler set \$schedulerEntry comment=\"\$currentMonth\";\
    \n\
    \n        :local iTBotToken [/system script get [find name=\"bottoken\"] source];\
    \n        :local iTGrChatID [/system script get [find name=\"chatid\"] source];\
    \n        :local monthlyIncomeSource [/system script get [find name=\"monthlyincome\"] source];\
    \n\
    \n        :if (\$monthlyIncomeSource != \"0\") do={\
    \n            :local message (\"The income for this month is: \" . \$monthlyIncomeSource);\
    \n            :if (\$isTelegram=1) do={\
    \n                /tool fetch url=(\"https://api.telegram.org/bot\" . \$iTBotToken . \"/sendMessage\?chat_id=\" . \$iTGrChatID . \"&text=\" . \$message) keep-result=no;\
    \n            }\
    \n            :if (\$isDiscord=1) do={\
    \n                /tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"content=\" . \"```\$message```%0A** **\") mode=https keep-result=no;\
    \n            }\
    \n            :delay 1s;\
    \n        }\
    \n\
    \n        /system script set source=\"0\" [find name=\"monthlyincome\"];\
    \n    }\
    \n}" \
        policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon
}

# --- autorestart ---
:if ([/system scheduler find name="autorestart"] = "") do={
    /system scheduler add \
        interval=1d \
        name="autorestart" \
        on-event="/system reboot" \
        policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
        start-date=jun/11/2025 \
        start-time=03:00:00
} else={
    /system scheduler set [find name="autorestart"] \
        interval=1d \
        on-event="/system reboot" \
        policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon
}

/system scheduler; :foreach i in=[find where name~"yearly" and name!="reset yearly"] do={ set $i name="reset yearly"; :log info "renamed reset yearly income scheduler" }

# --- reset yearly ---
:if ([/system scheduler find name="reset yearly"] = "") do={
    /system scheduler add \
        interval=1h \
        name="reset yearly" \
        on-event=":local sntpStatus [/system ntp client get last-update-from];\
    \n:local currentDate [/system clock get date];\
    \n:local currentyear [:pick \$currentDate 7 11];\
    \n:local iTBotToken [/system script get [find name=\"bottoken\"] source];\
    \n:local iTGrChatID [/system script get [find name=\"chatid\"] source];\
    \n:local yearlyIncomeSource [/system script get [find name=\"yearlyincome\"] source];\
    \n:local isTelegram [:tonum [/system script get [find name=\"enabletelegram\"] source]];\
    \n:local isDiscord [:tonum [/system script get [find name=\"enablediscord\"] source]];\
    \n:local iDiscordWebhook [/system script get [find name=\"discordwebhook\"] source];\
    \n\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    # Get scheduler comment\
    \n    :local schedulerComment [/system scheduler get [find name=\"reset yearly\"] comment];\
    \n    \
    \n    :if (\$schedulerComment != \$currentyear) do={\
    \n        :if (\$yearlyIncomeSource != \"0\") do={\
    \n            :local message (\"The income for this year is: \" . \$yearlyIncomeSource);\
    \n            :if (\$isTelegram=1) do={\
    \n            /tool fetch url=(\"https://api.telegram.org/bot\" . \$iTBotToken . \"/sendMessage\?chat_id=\" . \$iTGrChatID . \"&text=\" . \$message) keep-result=no;\
    \n            }\
    \n            :if (\$isDiscord=1) do={\
    \n            /tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"content=\" . \"```\$message```%0A** **\") mode=https keep-result=no\
    \n            }\
    \n            :delay 1s;\
    \n        }\
    \n        \
    \n        /system script set source=\"0\" [find name=\"yearlyincome\"];\
    \n        \
    \n        /system scheduler set [find name=\"reset yearly\"] comment=\"\$currentyear\";\
    \n        \
    \n    } else={\
    \n        \
    \n    }\
    \n} else={\
    \n    \
    \n}" \
        policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
        start-date=jan/02/1970 \
        start-time=00:00:01
} else={
    /system scheduler set [find name="reset yearly"] \
        interval=1h \
        on-event=":local sntpStatus [/system ntp client get last-update-from];\
    \n:local currentDate [/system clock get date];\
    \n:local currentyear [:pick \$currentDate 7 11];\
    \n:local iTBotToken [/system script get [find name=\"bottoken\"] source];\
    \n:local iTGrChatID [/system script get [find name=\"chatid\"] source];\
    \n:local yearlyIncomeSource [/system script get [find name=\"yearlyincome\"] source];\
    \n:local isTelegram [:tonum [/system script get [find name=\"enabletelegram\"] source]];\
    \n:local isDiscord [:tonum [/system script get [find name=\"enablediscord\"] source]];\
    \n:local iDiscordWebhook [/system script get [find name=\"discordwebhook\"] source];\
    \n\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    # Get scheduler comment\
    \n    :local schedulerComment [/system scheduler get [find name=\"reset yearly\"] comment];\
    \n    \
    \n    :if (\$schedulerComment != \$currentyear) do={\
    \n        :if (\$yearlyIncomeSource != \"0\") do={\
    \n            :local message (\"The income for this year is: \" . \$yearlyIncomeSource);\
    \n            :if (\$isTelegram=1) do={\
    \n            /tool fetch url=(\"https://api.telegram.org/bot\" . \$iTBotToken . \"/sendMessage\?chat_id=\" . \$iTGrChatID . \"&text=\" . \$message) keep-result=no;\
    \n            }\
    \n            :if (\$isDiscord=1) do={\
    \n            /tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"content=\" . \"```\$message```%0A** **\") mode=https keep-result=no\
    \n            }\
    \n            :delay 1s;\
    \n        }\
    \n        \
    \n        /system script set source=\"0\" [find name=\"yearlyincome\"];\
    \n        \
    \n        /system scheduler set [find name=\"reset yearly\"] comment=\"\$currentyear\";\
    \n        \
    \n    } else={\
    \n        \
    \n    }\
    \n} else={\
    \n    \
    \n}" \
        policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon
}

/ip hotspot user profile
set [ find default=yes ] add-mac-cookie=no keepalive-timeout=3m name=\
    autospeedlimit on-login="# ===============================================\
    =============\
    \n# Hotspot Login Script (Optimized)\
    \n# ============================================================\
    \n\
    \n# --- Clock ---\
    \n:local date [/system clock get date];\
    \n:local time [/system clock get time];\
    \n\
    \n# --- Interface Throughput ---\
    \n:local ifName \"ether1\";\
    \n:local rxBps; :local txBps;\
    \n/interface monitor-traffic \$ifName once do={\
    \n    :set rxBps \$\"rx-bits-per-second\";\
    \n    :set txBps \$\"tx-bits-per-second\";\
    \n}\
    \n:local rxKbps (\$rxBps / 1000);\
    \n:local txKbps (\$txBps / 1000);\
    \n\
    \n:local rxStr \"\";\
    \n:if (\$rxKbps >= 1000) do={\
    \n    :set rxStr ((\$rxKbps / 1000) . \".\" . ((\$rxKbps % 1000) / 100) . \
    \" Mbps\");\
    \n} else={\
    \n    :set rxStr (\"\$rxKbps Kbps\");\
    \n}\
    \n:local txStr \"\";\
    \n:if (\$txKbps >= 1000) do={\
    \n    :set txStr ((\$txKbps / 1000) . \".\" . ((\$txKbps % 1000) / 100) . \
    \" Mbps\");\
    \n} else={\
    \n    :set txStr (\"\$txKbps Kbps\");\
    \n}\
    \n:local queueRate (\"\$rxStr | \$txStr\");\
    \n\
    \n# --- MAC / Address ---\
    \n:local mac    \$\"mac-address\";\
    \n:local addr   \$\"address\";\
    \n:local macNoCol (\"\$[:pick \$mac 0 2]\$[:pick \$mac 3 5]\$[:pick \$mac \
    6 8]\$[:pick \$mac 9 11]\$[:pick \$mac 12 14]\$[:pick \$mac 15 17]\");\
    \n\
    \n# --- Device Name ---\
    \n:local deviceName [/ip dhcp-server lease get [find mac-address=\$mac] ho\
    st-name];\
    \n:if ([:len \$deviceName] = 0) do={ :set deviceName \"N/A\"; }\
    \n\
    \n# --- Hotspot User (single fetch) ---\
    \n:local uID [/ip hotspot user find name=\$user];\
    \n:local limit    [/ip hotspot user get \$uID limit-uptime];\
    \n:local uptime   [/ip hotspot user get \$uID uptime];\
    \n:local com      [/ip hotspot user get \$uID comment];\
    \n:local aUsrNote [:toarray \$com];\
    \n:local iSaleAmt [:tonum (\$aUsrNote->1)];\
    \n\
    \n:local totaltime \$limit;\
    \n:local remainingt (\$limit - \$uptime);\
    \n:local totaluptime (\$limit - \$remainingt);\
    \n:local validity \"\";\
    \n\
    \n# --- System Resources ---\
    \n:local cpuusage [/system resource get cpu-load];\
    \n:local freeRam  [/system resource get free-memory];\
    \n:local ramMB    (\$freeRam / 1048576);\
    \n:local ramdecimal ((\$freeRam % 1048576) / 104858);\
    \n\
    \n# --- Active User Count (single fetch, reused below) ---\
    \n:local uactive [/ip hotspot active print count-only];\
    \n\
    \n# --- Notification Config ---\
    \n:local hotspotFolder \"hotspot\";\
    \n:local isTelegram  [:tonum [/system script get [find name=\"enabletelegr\
    am\"] source]];\
    \n:local iTBotToken  [/system script get [find name=\"bottoken\"] source];\
    \n:local iTGrChatID  [/system script get [find name=\"chatid\"] source];\
    \n:local isDiscord   [:tonum [/system script get [find name=\"enablediscor\
    d\"] source]];\
    \n:local iDiscordWebhook [/system script get [find name=\"discordwebhook\"\
    ] source];\
    \n\
    \n# --- Sales Tracking ---\
    \n:local todaysales  [:tonum [/system script get todayincome source]];\
    \n:local mnthlysales [:tonum [/system script get monthlyincome source]];\
    \n:local yearlysales [:tonum [/system script get yearlyincome source]];\
    \n:local iDailySales (\$iSaleAmt + \$todaysales);\
    \n:local iMonthSales (\$iSaleAmt + \$mnthlysales);\
    \n:local iYearSales  (\$iSaleAmt + \$yearlysales);\
    \n\
    \n# --- Update Sales (only if this is a new purchase, not a resume) ---\
    \n:if (\$com != \"\") do={\
    \n    /system script set todayincome   source=\"\$iDailySales\";\
    \n    /system script set monthlyincome source=\"\$iMonthSales\";\
    \n    /system script set yearlyincome  source=\"\$iYearSales\";\
    \n    :set validity [:pick \$com 0 [:find \$com \",\"]];\
    \n}\
    \n\
    \n# --- Resume Notification (comment was empty = resuming session) ---\
    \n:if (\$com = \"\") do={\
    \n    :local rtimeMessage (\"\$user%20resumed%20time,%20remaining%20time%2\
    0is%20\$remainingt%0AActive%20Users:%20\$uactive\");\
    \n    :if (\$isTelegram = 1) do={\
    \n        /tool fetch url=\"https://api.telegram.org/bot\$iTBotToken/sendM\
    essage\?chat_id=\$iTGrChatID&text=\$rtimeMessage\" keep-result=no;\
    \n    }\
    \n    :if (\$isDiscord = 1) do={\
    \n        /tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"\
    content=\" . \"```\$rtimeMessage```%0A** **\") mode=https keep-result=no;\
    \n    }\
    \n}\
    \n# --- Fix 0m validity (NodeMCU failure fallback) ---\
    \n:if (\$validity = \"0m\") do={\
    \n    :local vendorIp \"10.0.0.5\";\
    \n    :local cachedRates [/system script get [find name=\"cachedrates\"] s\
    ource];\
    \n    :local foundValidity \"\";\
    \n    :local freshRates \"\";\
    \n    :local minutesCache \"\";\
    \n\
    \n    # Try fetching current rates from vendo\
    \n    :do {\
    \n        :set freshRates ([/tool fetch url=(\"http://10.0.0.5/getRates\?r\
    ateType=1\") output=user as-value]->\"data\")\
    \n    } on-error={}\
    \n\
    \n    :if (\$freshRates != \"\") do={\
    \n        # Parse pipe-delimited rates and rebuild cache\
    \n        :local newCache \"\";\
    \n        :local remaining \$freshRates;\
    \n        :local parsing true;\
    \n        :while (\$parsing = true) do={\
    \n            :local pipeIdx [:find \$remaining \"|\"];\
    \n            :local entry \"\";\
    \n            :if ([:len [:tostr \$pipeIdx]] > 0) do={\
    \n                :set entry [:pick \$remaining 0 \$pipeIdx];\
    \n                :set remaining [:pick \$remaining (\$pipeIdx + 1) [:len \
    \$remaining]];\
    \n            } else={\
    \n                :set entry \$remaining;\
    \n                :set parsing false;\
    \n            }\
    \n            :if ([:len \$entry] > 0) do={\
    \n                :local p1 [:find \$entry \"#\"];\
    \n                :local p2 [:find \$entry \"#\" (\$p1 + 1)];\
    \n                :local p3 [:find \$entry \"#\" (\$p2 + 1)];\
    \n                :local p4 [:find \$entry \"#\" (\$p3 + 1)];\
    \n\
    \n                :local eAmt     [:tonum [:pick \$entry (\$p1 + 1) \$p2]]\
    ;\
    \n                :local eValMins [:tonum [:pick \$entry (\$p3 + 1) \$p4]]\
    ;\
    \n\
    \n                # Convert minutes to RouterOS interval string\
    \n                :local days (\$eValMins / 1440);\
    \n                :local rem  (\$eValMins % 1440);\
    \n                :local hrs  (\$rem / 60);\
    \n                :local mins (\$rem % 60);\
    \n                :local hStr [:tostr \$hrs];  :if (\$hrs  < 10) do={ :set\
    \_hStr  \"0\$hrs\";  }\
    \n                :local mStr [:tostr \$mins]; :if (\$mins < 10) do={ :set\
    \_mStr \"0\$mins\"; }\
    \n                :local valStr \"\";\
    \n                :if (\$days > 0) do={\
    \n                    :set valStr (\"\$days\" . \"d\$hStr:\$mStr:00\");\
    \n                } else={\
    \n                    :set valStr \"\$hStr:\$mStr:00\";\
    \n                }\
    \n\
    \n                # Append to new cache string (format: amount:intervalStr\
    :minutes)\
    \n                :if (\$newCache != \"\") do={ :set newCache (\$newCache \
    . \",\"); }\
    \n                :set newCache (\$newCache . \"\$eAmt:\$valStr:\$eValMins\
    \");\
    \n\
    \n                # Build minutes cache for combination fallback\
    \n                :if (\$minutesCache != \"\") do={ :set minutesCache (\$m\
    inutesCache . \",\"); }\
    \n                :set minutesCache (\$minutesCache . \"\$eAmt:\$eValMins\
    \");\
    \n\
    \n                # Check if this rate exactly matches the paid amount\
    \n                :if (\$eAmt = \$iSaleAmt) do={\
    \n                    :set foundValidity \$valStr;\
    \n                }\
    \n            }\
    \n        }\
    \n\
    \n        # Only write to cache script if rates have changed\
    \n        :if (\$newCache != \$cachedRates) do={\
    \n            /system script set [find name=\"cachedrates\"] source=\$newC\
    ache;\
    \n        }\
    \n\
    \n    } else={\
    \n        # Vendo unreachable \E2\80\94 fall back to cached rates\
    \n        # Cache format: amount:intervalStr:minutes\
    \n        :foreach e in=[:toarray \$cachedRates] do={\
    \n            :local cp1 [:find \$e \":\"];\
    \n            :local cp2 [:find \$e \":\" (\$cp1 + 1)];\
    \n            :if ([:len [:tostr \$cp1]] > 0 && [:len [:tostr \$cp2]] > 0)\
    \_do={\
    \n                :local eAmt        [:tonum [:pick \$e 0 \$cp1]];\
    \n                :local eVal        [:pick \$e (\$cp1 + 1) \$cp2];\
    \n                :local eMinsStored [:tonum [:pick \$e (\$cp2 + 1) [:len \
    \$e]]];\
    \n\
    \n                :if (\$eAmt = \$iSaleAmt) do={\
    \n                    :set foundValidity \$eVal;\
    \n                }\
    \n\
    \n                # Build minutes cache from stored minutes\
    \n                :if (\$minutesCache != \"\") do={ :set minutesCache (\$m\
    inutesCache . \",\"); }\
    \n                :set minutesCache (\$minutesCache . \"\$eAmt:\$eMinsStor\
    ed\");\
    \n            }\
    \n        }\
    \n    }\
    \n\
    \n    # Greedy combination fallback (e.g. \E2\82\B16 = \E2\82\B15 + \E2\82\
    \B11)\
    \n    :if (\$foundValidity = \"\") do={\
    \n        :local remAmt \$iSaleAmt;\
    \n        :local totalMins 0;\
    \n        :local combined true;\
    \n\
    \n        :while (\$remAmt > 0 && \$combined = true) do={\
    \n            :set combined false;\
    \n            :local bestAmt 0;\
    \n            :local bestMins 0;\
    \n\
    \n            :foreach e in=[:toarray \$minutesCache] do={\
    \n                :local cp [:find \$e \":\"];\
    \n                :local eAmt [:tonum [:pick \$e 0 \$cp]];\
    \n                :local eMins [:tonum [:pick \$e (\$cp + 1) [:len \$e]]];\
    \n                :if (\$eAmt <= \$remAmt && \$eAmt > \$bestAmt) do={\
    \n                    :set bestAmt \$eAmt;\
    \n                    :set bestMins \$eMins;\
    \n                }\
    \n            }\
    \n\
    \n            :if (\$bestAmt > 0) do={\
    \n                :set totalMins (\$totalMins + \$bestMins);\
    \n                :set remAmt (\$remAmt - \$bestAmt);\
    \n                :set combined true;\
    \n            }\
    \n        }\
    \n\
    \n        # Only apply if amount was fully consumed with no remainder\
    \n        :if (\$remAmt = 0 && \$totalMins > 0) do={\
    \n            :local days (\$totalMins / 1440);\
    \n            :local rem  (\$totalMins % 1440);\
    \n            :local hrs  (\$rem / 60);\
    \n            :local mins (\$rem % 60);\
    \n            :local hStr [:tostr \$hrs];  :if (\$hrs  < 10) do={ :set hSt\
    r  \"0\$hrs\";  }\
    \n            :local mStr [:tostr \$mins]; :if (\$mins < 10) do={ :set mSt\
    r \"0\$mins\"; }\
    \n            :log info \"combining validity\";\
    \n            :if (\$days > 0) do={\
    \n                :set foundValidity (\"\$days\" . \"d\$hStr:\$mStr:00\");\
    \n            } else={\
    \n                :set foundValidity \"\$hStr:\$mStr:00\";\
    \n            }\
    \n            :log info \"Combined validity for P\$iSaleAmt: \$foundValidi\
    ty\";\
    \n        }\
    \n    }\
    \n\
    \n    # Apply corrected validity\
    \n    :if (\$foundValidity != \"\") do={\
    \n        :set validity \$foundValidity;\
    \n    } else={\
    \n        :log warning \"No valid rate found for P\$iSaleAmt, session will\
    \_have the validity not added.\";\
    \n    }\
    \n}\
    \n\
    \n# --- Clear comment flag ---\
    \n/ip hotspot user set comment=\"\" \$user;\
    \n\
    \n# --- New Purchase: Scheduler + Notification ---\
    \n:if (\$com != \"\") do={\
    \n    :if (\$validity != \"0m\") do={\
    \n        :local sc [/sys scheduler find name=\$user];\
    \n        :if (\$sc = \"\") do={\
    \n            /sys sch add name=\"\$user\" disable=no start-date=\$date in\
    terval=\$validity \\\
    \n                on-event=\"/ip hotspot user remove [find name=\$user]; /\
    ip hotspot active remove [find user=\$user]; /ip hotspot cookie remove [fi\
    nd user=\$user]; /system sche remove [find name=\$user]; /file remove \\\"\
    \$hotspotFolder/data/\$macNoCol.txt\\\";\" \\\
    \n                policy=ftp,reboot,read,write,policy,test,password,sniff,\
    sensitive,romon;\
    \n            :delay 2s;\
    \n        } else={\
    \n            :local sint [/sys scheduler get \$user interval];\
    \n            :if (\$validity != \"\") do={\
    \n                /sys scheduler set \$user interval (\$sint + \$validity)\
    ;\
    \n            }\
    \n        }\
    \n    }\
    \n\
    \n    :local fileScheduler \"FILE\$macNoCol\";\
    \n    :local fsc [/sys scheduler find name=\$fileScheduler];\
    \n    :local validUntil [/sys scheduler get \$user next-run];\
    \n    :if (\$fsc != \"\") do={\
    \n        /system scheduler remove [find name=\$fileScheduler];\
    \n    }\
    \n    :do {\
    \n        /system scheduler add name=\"\$fileScheduler\" interval=5 \\\
    \n            start-date=[/system clock get date] start-time=[/system cloc\
    k get time] disable=no \\\
    \n            policy=ftp,reboot,read,write,policy,test,password,sniff,sens\
    itive,romon \\\
    \n            on-event=(\"/system scheduler set \$fileScheduler interval 0\
    ;\\r\\n\".\\\
    \n                      \"/file print file=\\\"\$hotspotFolder/data/\$macN\
    oCol\\\" where name=\\\"dummyfile\\\";\\r\\n\".\\\
    \n                      \":delay 1s;\\r\\n\".\\\
    \n                      \"/file set \\\"\$hotspotFolder/data/\$macNoCol\\\
    \" contents=\\\"\$user#\$validUntil\\\";\\r\\n\".\\\
    \n                      \":log warning \\\"parallel script executed succes\
    sfully.\\\";\\r\\n\")\
    \n    } on-error={ :log error \"parallel script creation error.\"; }\
    \n\
    \n    # --- Estimates ---\
    \n    :local currentday [:pick \$date 4 6];\
    \n    :local estimatedperday (\$mnthlysales / \$currentday);\
    \n    :local estimatedpermonth (\$estimatedperday * 30);\
    \n    :local iValidUntil [/system scheduler get \$user next-run];\
    \n\
    \n    # --- Login Notification ---\
    \n    :local loginMessage (\"Information:%0ACoin:%20\\E2\\82\\B1%20\$iSale\
    Amt%0AUser:%20\$user%0ADevice%20Name:%20\$deviceName%0ATotal%20Time:%20\$t\
    otaltime%0AUsed%20Time:%20\$totaluptime%0ARemaining%20Time:%20\$remainingt\
    %0AExpires%20On:%20\$iValidUntil%0A%0ACurrent:%0AToday%20Sales:%20\\E2\\82\
    \\B1%20\$iDailySales%0AIncome%20This%20Month:%20\\E2\\82\\B1%20\$iMonthSal\
    es%0AIncome%20This%20Year:%20\\E2\\82\\B1%20\$iYearSales%0AActive%20Users:\
    %20\$uactive%0A%0ASystem%20Information:%0ACPU%20Usage:%20\$cpuusage%25%0AR\
    emaining%20Memory:%20\$ramMB.\$ramdecimal%20MB%0ACurrent%20Throughput:%20\
    \$queueRate%0A%0AEstimates:%0AEstimated%20Per%20Day:%20\\E2\\82\\B1%20\$es\
    timatedperday%0AEstimated%20Per%20Month:%20\\E2\\82\\B1%20\$estimatedpermo\
    nth%0A%0A(Note:%20The%20Estimates%20are%20not%20the%20current%20sales.)%0A\
    %0ADate%20%26%20Timestamp:%20\$date%20\$time\");\
    \n    :if (\$isTelegram = 1) do={\
    \n        /tool fetch url=\"https://api.telegram.org/bot\$iTBotToken/sendM\
    essage\?chat_id=\$iTGrChatID&text=\$loginMessage\" keep-result=no;\
    \n    }\
    \n    :if (\$isDiscord = 1) do={\
    \n        /tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"\
    content=\" . \"```\$loginMessage```%0A** **\") mode=https keep-result=no;\
    \n    }\
    \n}\
    \n# --- Update max active users record ---\
    \n:local rawSource [/system script get [find name=\"maxactiveusers\"] sour\
    ce];\
    \n:local maxActiveUsers 0;\
    \n:if ([:len \$rawSource] > 0) do={\
    \n    :set maxActiveUsers [\$rawSource];\
    \n}\
    \n:if (\$uactive > \$maxActiveUsers) do={\
    \n    /system script set [find name=\"maxactiveusers\"] source=\"\$uactive\
    \";\
    \n}\
    \n\
    \n:log info \"\$validity\";" on-logout="# ================================\
    ============================\
    \n# Hotspot Logout Script (Optimized)\
    \n# ============================================================\
    \n\
    \n# --- MAC / Path Setup ---\
    \n:local mac       \$\"mac-address\";\
    \n:local macNoCol  (\"\$[:pick \$mac 0 2]\$[:pick \$mac 3 5]\$[:pick \$mac\
    \_6 8]\$[:pick \$mac 9 11]\$[:pick \$mac 12 14]\$[:pick \$mac 15 17]\");\
    \n:local hotspotFolder \"hotspot\";\
    \n\
    \n# --- Notification Config (fetch all upfront) ---\
    \n:local isTelegram      [:tonum [/system script get [find name=\"enablete\
    legram\"] source]];\
    \n:local isDiscord       [:tonum [/system script get [find name=\"enabledi\
    scord\"] source]];\
    \n:local iDiscordWebhook [/system script get [find name=\"discordwebhook\"\
    ] source];\
    \n:local iTBotToken      [/system script get [find name=\"bottoken\"] sour\
    ce];\
    \n:local iTGrChatID      [/system script get [find name=\"chatid\"] source\
    ];\
    \n\
    \n# --- Hotspot User (single find, reused throughout) ---\
    \n:local uID  [/ip hotspot user find name=\$user];\
    \n:local com  \"\";\
    \n:local uLimit  0s;\
    \n:local uUptime 0s;\
    \n:if ([:len \$uID] > 0) do={\
    \n    :set com    [/ip hotspot user get \$uID comment];\
    \n    :set uLimit [/ip hotspot user get \$uID limit-uptime];\
    \n    :set uUptime [/ip hotspot user get \$uID uptime];\
    \n}\
    \n\
    \n# --- Expire user if time is used up ---\
    \n:if (\$uLimit <= \$uUptime) do={\
    \n    /ip hotspot user remove \$user;\
    \n    /file remove \"\$hotspotFolder/data/\$macNoCol.txt\";\
    \n    /system sche remove [find name=\$user];\
    \n}\
    \n\
    \n# --- Clean up file scheduler ---\
    \n:local fileScheduler \"FILE\$macNoCol\";\
    \n:if ([/sys scheduler find name=\$fileScheduler] != \"\") do={\
    \n    /system scheduler remove [find name=\$fileScheduler];\
    \n}\
    \n\
    \n# --- Clean up retry scheduler (FIX: was missing \$ on variable) ---\
    \n:local retryScheduler \"RETRY\$macNoCol\";\
    \n:if ([/sys scheduler find name=\$retryScheduler] != \"\") do={\
    \n    /system scheduler remove [find name=\$retryScheduler];\
    \n}\
    \n\
    \n# --- Cause-based Notifications ---\
    \n\
    \n# Session timeout (FIX: \$timeoutmessage -> \$timeoutMessage in Discord \
    block)\
    \n:if (\$cause = \"session timeout\") do={\
    \n    :local timeoutMessage (\"\$user ran out of time!\");\
    \n    :if (\$isTelegram = 1) do={\
    \n        /tool fetch url=\"https://api.telegram.org/bot\$iTBotToken/sendM\
    essage\?chat_id=\$iTGrChatID&text=\$timeoutMessage\" keep-result=no;\
    \n    }\
    \n    :if (\$isDiscord = 1) do={\
    \n        /tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"\
    content=\" . \"```\$timeoutMessage```%0A** **\") mode=https keep-result=no\
    ;\
    \n    }\
    \n}\
    \n\
    \n# User-requested pause (only when no active purchase in comment)\
    \n:if (\$com = \"\" && \$cause = \"user request\") do={\
    \n    :local pauseMessage (\"\$user paused time.\");\
    \n    :if (\$isTelegram = 1) do={\
    \n        /tool fetch url=\"https://api.telegram.org/bot\$iTBotToken/sendM\
    essage\?chat_id=\$iTGrChatID&text=\$pauseMessage\" keep-result=no;\
    \n    }\
    \n    :if (\$isDiscord = 1) do={\
    \n        /tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"\
    content=\" . \"```\$pauseMessage```%0A** **\") mode=https keep-result=no;\
    \n    }\
    \n}\
    \n\
    \n# Keepalive timeout (auto-pause)\
    \n:if (\$cause = \"keepalive timeout\") do={\
    \n    :local timeoutMessage (\"automatically paused time for \$user\");\
    \n    :if (\$isTelegram = 1) do={\
    \n        /tool fetch url=\"https://api.telegram.org/bot\$iTBotToken/sendM\
    essage\?chat_id=\$iTGrChatID&text=\$timeoutMessage\" keep-result=no;\
    \n    }\
    \n    :if (\$isDiscord = 1) do={\
    \n        /tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"\
    content=\" . \"```\$timeoutMessage```%0A** **\") mode=https keep-result=no\
    ;\
    \n    }\
    \n}\
    \n\
    \n# Admin kick\
    \n:if (\$cause = \"admin reset\") do={\
    \n    :local kickMessage (\"admin kicked \$user\");\
    \n    :if (\$isTelegram = 1) do={\
    \n        /tool fetch url=\"https://api.telegram.org/bot\$iTBotToken/sendM\
    essage\?chat_id=\$iTGrChatID&text=\$kickMessage\" keep-result=no;\
    \n    }\
    \n    :if (\$isDiscord = 1) do={\
    \n        /tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"\
    content=\" . \"```\$kickMessage```%0A** **\") mode=https keep-result=no;\
    \n    }\
    \n}\
    \n\
    \n# --- Write session file if user still exists (reuse cached uID) ---\
    \n:local iValidUntil [/system scheduler get \$user next-run];\
    \n:if ([:len \$uID] > 0) do={\
    \n    :local myfile \"\$hotspotFolder/data/\$user.txt\";\
    \n    :if ([:len [/file find name=\$myfile]] = 0) do={\
    \n        /file print file=\$myfile;\
    \n        :delay 1s;\
    \n        /file set \$myfile contents=\"\$user#\$iValidUntil\";\
    \n    }\
    \n}\
    \n" shared-users=2
