:foreach sName in={"enabletelegram";"bottoken";"chatid";"enablediscord";"discordwebhook";"todayincome";"monthlyincome";"yearlyincome"} do={
    :if ([:len [/system script find name=$sName]] = 0) do={
        /system script add name=$sName source="0" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon;
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
    \n    :local schedulerComment [/system scheduler get [find name=\"Reset Daily Income\"] comment];\
    \n    \
    \n    :if (\$schedulerComment != \$currentday) do={\
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
    \n        /system script set source=\"0\" [find name=\"todayincome\"];\
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
    \n    :local schedulerComment [/system scheduler get [find name=\"Reset Daily Income\"] comment];\
    \n    \
    \n    :if (\$schedulerComment != \$currentday) do={\
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
    \n        /system script set source=\"0\" [find name=\"todayincome\"];\
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

# --- maxactiveusers ---
:if ([/system scheduler find name="maxactiveusers"] = "") do={
    /system scheduler add \
        interval=15m \
        name="maxactiveusers" \
        on-event=":local activeUsers [/ip hotspot active print count-only];\
    \n\
    \n# Read stored max from this scheduler's comment\
    \n:local schedulerEntry [/system scheduler find name=\"maxactiveusers\"];\
    \n:local currentSource [/system scheduler get \$schedulerEntry comment];\
    \n:local maxActiveUsers 0;\
    \n\
    \n:if ([:len \$currentSource] > 0) do={\
    \n    :set maxActiveUsers [:tonum \$currentSource];\
    \n}\
    \n\
    \n:if (\$activeUsers > \$maxActiveUsers) do={\
    \n    /system scheduler set \$schedulerEntry comment=\"\$activeUsers\";\
    \n}" \
        policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
        start-time=startup
} else={
    /system scheduler set [find name="maxactiveusers"] \
        interval=15m \
        on-event=":local activeUsers [/ip hotspot active print count-only];\
    \n\
    \n# Read stored max from this scheduler's comment\
    \n:local schedulerEntry [/system scheduler find name=\"maxactiveusers\"];\
    \n:local currentSource [/system scheduler get \$schedulerEntry comment];\
    \n:local maxActiveUsers 0;\
    \n\
    \n:if ([:len \$currentSource] > 0) do={\
    \n    :set maxActiveUsers [:tonum \$currentSource];\
    \n}\
    \n\
    \n:if (\$activeUsers > \$maxActiveUsers) do={\
    \n    /system scheduler set \$schedulerEntry comment=\"\$activeUsers\";\
    \n}" \
        policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
        start-time=startup
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
    \n        :local maxActiveUsersSource [/system script get [find name=\"maxactiveusers\"] source];\
    \n        :local isTelegram [:tonum [/system script get [find name=\"enabletelegram\"] source]];\
    \n\
    \n        :local isDiscord [:tonum [/system script get [find name=\"enablediscord\"] source]];\
    \n        :local iDiscordWebhook [/system script get [find name=\"discordwebhook\"] source];\
    \n\
    \n        :if (\$maxActiveUsersSource != \"0\") do={\
    \n            :local message (\"The top active users for today is: \" . \$maxActiveUsersSource);\
    \n            :if (\$isDiscord=1) do={\
    \n            /tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"content=\" . \"```\$message```%0A** **\") mode=https keep-result=no\
    \n            }\
    \n            :if (\$isTelegram=1) do={\
    \n            /tool fetch url=(\"https://api.telegram.org/bot\" . \$iTBotToken . \"/sendMessage\?chat_id=\" . \$iTGrChatID . \"&text=\" . \$message) keep-result=no;\
    \n            }\
    \n            \
    \n            :delay 1s;\
    \n        }\
    \n\
    \n        /system script set source=\"0\" [find name=\"maxactiveusers\"];\
    \n        /system scheduler set [find name=\"reset maxactiveusers\"] comment=\"\$currentday\";\
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
    \n        :local maxActiveUsersSource [/system script get [find name=\"maxactiveusers\"] source];\
    \n        :local isTelegram [:tonum [/system script get [find name=\"enabletelegram\"] source]];\
    \n\
    \n        :local isDiscord [:tonum [/system script get [find name=\"enablediscord\"] source]];\
    \n        :local iDiscordWebhook [/system script get [find name=\"discordwebhook\"] source];\
    \n\
    \n        :if (\$maxActiveUsersSource != \"0\") do={\
    \n            :local message (\"The top active users for today is: \" . \$maxActiveUsersSource);\
    \n            :if (\$isDiscord=1) do={\
    \n            /tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"content=\" . \"```\$message```%0A** **\") mode=https keep-result=no\
    \n            }\
    \n            :if (\$isTelegram=1) do={\
    \n            /tool fetch url=(\"https://api.telegram.org/bot\" . \$iTBotToken . \"/sendMessage\?chat_id=\" . \$iTGrChatID . \"&text=\" . \$message) keep-result=no;\
    \n            }\
    \n            \
    \n            :delay 1s;\
    \n        }\
    \n\
    \n        /system script set source=\"0\" [find name=\"maxactiveusers\"];\
    \n        /system scheduler set [find name=\"reset maxactiveusers\"] comment=\"\$currentday\";\
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
    \n    :local schedulerEntry [/system scheduler find name=\"resetmonthly\"];\
    \n    :local storedMonth [/system scheduler get \$schedulerEntry comment];\
    \n\
    \n    :if (\$storedMonth != \$currentMonth) do={\
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
    \n    :local schedulerEntry [/system scheduler find name=\"resetmonthly\"];\
    \n    :local storedMonth [/system scheduler get \$schedulerEntry comment];\
    \n\
    \n    :if (\$storedMonth != \$currentMonth) do={\
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
    autospeedlimit on-login="# Get User Data\
    \n:local date [ /system clock get date]\
    \n:local time [ /system clock get time]\
    \n\
    \n:local ifName \"ether1\"\
    \n:local rxBps\
    \n:local txBps\
    \n/interface monitor-traffic \$ifName once do={\
    \n    :set rxBps \$\"rx-bits-per-second\"\
    \n    :set txBps \$\"tx-bits-per-second\"\
    \n}\
    \n\
    \n:local rxKbps (\$rxBps / 1000)\
    \n:local txKbps (\$txBps / 1000)\
    \n\
    \n# Format RX\
    \n:local rxStr \"\"\
    \n:if (\$rxKbps >= 1000) do={\
    \n    :set rxStr ((\$rxKbps / 1000) . \".\" . ((\$rxKbps % 1000) / 100) . \
    \" Mbps\")\
    \n} else={\
    \n    :set rxStr (\"\$rxKbps Kbps\")\
    \n}\
    \n\
    \n# Format TX\
    \n:local txStr \"\"\
    \n:if (\$txKbps >= 1000) do={\
    \n    :set txStr ((\$txKbps / 1000) . \".\" . ((\$txKbps % 1000) / 100) . \
    \" Mbps\")\
    \n} else={\
    \n    :set txStr (\"\$txKbps Kbps\")\
    \n}\
    \n:local queueRate (\"\$rxStr | \$txStr\")\
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
    \n:local isTelegram [:tonum [/system script get [find name=\"enabletelegra\
    m\"] source]];\
    \n:local iTBotToken [/system script get [find name=\"bottoken\"] source];\
    \n:local iTGrChatID [/system script get [find name=\"chatid\"] source];\
    \n### hotspot folder for HEX put flash/hotspot for haplite put hotspot onl\
    y\
    \n:local HSFilePath \"hotspot\";\
    \n:local uactive [/ip hotspot active print count-only];\
    \n\
    \n### enable discord notification, change from 0 to 1 to enable\
    \n:local isDiscord [:tonum [/system script get [find name=\"enablediscord\
    \"] source]];\
    \n:local iDiscordWebhook [/system script get [find name=\"discordwebhook\"\
    ] source];\
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
    \n:local rtimeMessage (\"\$user%20resumed%20time,%20remaining%20time%20is%\
    20\$remainingt%0AActive%20Users:%20\$uactive\");\
    \n:if (\$isTelegram=1) do={\
    \n    /tool fetch url=\"https://api.telegram.org/bot\$iTBotToken/sendMessa\
    ge\?chat_id=\$iTGrChatID&text=\$rtimeMessage\" keep-result=no;\
    \n}\
    \nif (\$isDiscord=1) do={\
    \n    /tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"cont\
    ent=\" . \"```\$rtimeMessage```%0A** **\") mode=https keep-result=no\
    \n}\
    \n    \
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
    \n\
    \n\
    \n:local loginMessage (\"Information:%0ACoin:%20\E2\82\B1%20\$iSaleAmt%0AU\
    ser:%20\$user%0ADevice%20Name:%20\$deviceName%0ATotal%20Time:%20\$totaltim\
    e%0AUsed%20Time:%20\$totaluptime%0ARemaining%20Time:%20\$remainingt%0AExpi\
    res%20On:%20\$iValidUntil%0A%0ACurrent:%0AToday%20Sales:%20\E2\82\B1%20\$i\
    DailySales%0AIncome%20This%20Month:%20\E2\82\B1%20\$iMonthSales%0AIncome%2\
    0This%20Year:%20\$iYearSales%0AActive%20Users:%20\$uactive%0A%0ASystem%20I\
    nformation:%0ACPU%20Usage:%20\$cpuusage%25%0ARemaining%20Memory:%20\$ramMB\
    .\$ramdecimal%20MB%0ACurrent%20Throughput:%20\$queueRate%0A%0AEstimates:%0\
    AEstimated%20Per%20Day:%20\E2\82\B1%20\$estimatedperday%0AEstimated%20Per%\
    20Month:%20\E2\82\B1%20\$estimatedpermonth%0A%0A(Note:%20The%20Estimates%2\
    0are%20not%20the%20current%20sales.)%0A%0ADate%20%26%20Timestamp:%20\$date\
    %20\$time\");\
    \n    :if (\$isTelegram=1) do={\
    \n    /tool fetch url=\"https://api.telegram.org/bot\$iTBotToken/sendMessa\
    ge\?chat_id=\$iTGrChatID&text=\$loginMessage\" keep-result=no;\
    \n    }\
    \n    :if (\$isDiscord=1) do={\
    \n    /tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"cont\
    ent=\" . \"```\$loginMessage```%0A** **\") mode=https keep-result=no\
    \n    }\
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
    \n:local mac \$\"mac-address\";\
    \n:local addr \$\"address\";\
    \n\
    \n# Remove old host entries for this MAC (different IP)\
    \n:foreach h in=[/ip hotspot host find mac-address=\$mac] do={\
    \n  :if ([/ip hotspot host get \$h address] != \$addr) do={\
    \n    /ip hotspot host remove \$h;\
    \n  }\
    \n}\
    \n\
    \n# Kick old active sessions for this MAC (different IP)\
    \n:foreach a in=[/ip hotspot active find mac-address=\$mac] do={\
    \n  :if ([/ip hotspot active get \$a address] != \$addr) do={\
    \n    /ip hotspot active remove \$a;\
    \n  }\
    \n}\
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
    \n:local isTelegram [:tonum [/system script get [find name=\"enabletelegra\
    m\"] source]];\
    \n### enable discord notification, change from 0 to 1 to enable\
    \n:local isDiscord [:tonum [/system script get [find name=\"enablediscord\
    \"] source]];\
    \n:local iDiscordWebhook [/system script get [find name=\"discordwebhook\"\
    ] source];\
    \n\
    \n:local iTBotToken [/system script get [find name=\"bottoken\"] source];\
    \n:local iTGrChatID [/system script get [find name=\"chatid\"] source];\
    \n# Check for session timeout and send notification\
    \n:if (\$cause=\"session timeout\") do={\
    \n:local timeoutMessage (\"\$user ran out of time!\");\
    \n:if (\$isTelegram=1) do={\
    \n/tool fetch url=\"https://api.telegram.org/bot\$iTBotToken/sendMessage\?\
    chat_id=\$iTGrChatID&text=\$timeoutMessage\" keep-result=no;\
    \n}\
    \n:if (\$isDiscord=1) do={\
    \n/tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"content=\
    \" . \"```\$timeoutmessage```%0A** **\") mode=https keep-result=no\
    \n}\
    \n}\
    \n\
    \n:if (\$com=\"\") do={\
    \n:if (\$cause=\"user request\") do={\
    \n:local pauseMessage (\"\$user paused time.\");\
    \n:if (\$isTelegram=1) do={  \
    \n  /tool fetch url=\"https://api.telegram.org/bot\$iTBotToken/sendMessage\
    \?chat_id=\$iTGrChatID&text=\$pauseMessage\" keep-result=no;\
    \n}\
    \n:if (\$isDiscord=1) do={\
    \n/tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"content=\
    \" . \"```\$pauseMessage```%0A** **\") mode=https keep-result=no\
    \n}\
    \n}\
    \n}\
    \n\
    \n\
    \n\
    \n:if (\$cause=\"keepalive timeout\") do={\
    \n:local timeoutMessage (\"automatically paused time for \$user\");\
    \n:if (\$isTelegram=1) do={\
    \n/tool fetch url=\"https://api.telegram.org/bot\$iTBotToken/sendMessage\?\
    chat_id=\$iTGrChatID&text=\$timeoutMessage\" keep-result=no;\
    \n}\
    \n:if (\$isDiscord=1) do={\
    \n/tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"content=\
    \" . \"```\$timeoutMessage```%0A** **\") mode=https keep-result=no\
    \n}\
    \n}\
    \n\
    \n:if (\$cause=\"admin reset\") do={ \
    \n  :local kickMessage (\"admin kicked \$user\");\
    \n:if (\$isTelegram=1) do={\
    \n/tool fetch url=\"https://api.telegram.org/bot\$iTBotToken/sendMessage\?\
    chat_id=\$iTGrChatID&text=\$kickMessage\" keep-result=no;\
    \n}\
    \n:if (\$isDiscord=1) do={\
    \n/tool fetch url=\$iDiscordWebhook http-method=post http-data=(\"content=\
    \" . \"```\$kickMessage```%0A** **\") mode=https keep-result=no\
    \n}\
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
