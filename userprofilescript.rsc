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
:log info "done ntp";

# --- uptime backup ---
:if ([/system scheduler find name="uptime backup"] = "") do={
/system scheduler add name="uptime backup" interval=15m on-event=":local hsuser;\
    \n:local schid;\
    \n:foreach i in=[/ip hotspot active find] do={\
    \n  :set hsuser [/ip hotspot active get \$i user];\
    \n  :set schid [/system scheduler find name=\$hsuser];\
    \n  \
    \n  :if ([:len \$schid] > 0) do={\
    \n    # Explicitly cast the time value to a string using :tostr for concat\
    enation\
    \n    /system scheduler set \$schid comment=(\"temp \" . [:tostr [/ip hots\
    pot active get \$i session-time-left]]);\
    \n  }\
    \n}\
    \n" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jun/01/2026 start-time=00:00:01
} else={
/system scheduler set [find name="uptime backup"] interval=15m on-event=":local hsuser;\
    \n:local schid;\
    \n:foreach i in=[/ip hotspot active find] do={\
    \n  :set hsuser [/ip hotspot active get \$i user];\
    \n  :set schid [/system scheduler find name=\$hsuser];\
    \n  \
    \n  :if ([:len \$schid] > 0) do={\
    \n    # Explicitly cast the time value to a string using :tostr for concat\
    enation\
    \n    /system scheduler set \$schid comment=(\"temp \" . [:tostr [/ip hots\
    pot active get \$i session-time-left]]);\
    \n  }\
    \n}\
    \n" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jun/01/2026 start-time=00:00:01
}

:log info "done uptime backup";
# --- uptime restore ---
:if ([/system scheduler find name="uptime restore"] = "") do={
/system scheduler add name="uptime restore" on-event=":local schuser;\
    \n:local timeleft;\
    \n:local userid;\
    \n:foreach i in=[/system scheduler find] do={\
    \n  :set timeleft [:tostr [/system scheduler get \$i comment]];\
    \n  \
    \n  # Replaced regex (~) with a strict pick for broader v6 compatibility\
    \n  :if ([:pick \$timeleft 0 5] = \"temp \") do={\
    \n    :set schuser [/system scheduler get \$i name];\
    \n    :set userid [/ip hotspot user find name=\$schuser];\
    \n    \
    \n    :if ([:len \$userid] > 0) do={\
    \n      /ip hotspot user reset-counters \$userid;\
    \n      \
    \n      # Explicitly cast the extracted string to a time type using :totim\
    e\
    \n      /ip hotspot user set \$userid limit-uptime=[:totime [:pick \$timel\
    eft 5 [:len \$timeleft]]];\
    \n      /system scheduler set \$i comment=\"\";\
    \n    } else={\
    \n      /system scheduler remove \$i;\
    \n    }\
    \n  }\
    \n}\
    \n" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-time=startup
} else={
/system scheduler set [find name="uptime restore"] on-event=":local schuser;\
    \n:local timeleft;\
    \n:local userid;\
    \n:foreach i in=[/system scheduler find] do={\
    \n  :set timeleft [:tostr [/system scheduler get \$i comment]];\
    \n  \
    \n  # Replaced regex (~) with a strict pick for broader v6 compatibility\
    \n  :if ([:pick \$timeleft 0 5] = \"temp \") do={\
    \n    :set schuser [/system scheduler get \$i name];\
    \n    :set userid [/ip hotspot user find name=\$schuser];\
    \n    \
    \n    :if ([:len \$userid] > 0) do={\
    \n      /ip hotspot user reset-counters \$userid;\
    \n      \
    \n      # Explicitly cast the extracted string to a time type using :totim\
    e\
    \n      /ip hotspot user set \$userid limit-uptime=[:totime [:pick \$timel\
    eft 5 [:len \$timeleft]]];\
    \n      /system scheduler set \$i comment=\"\";\
    \n    } else={\
    \n      /system scheduler remove \$i;\
    \n    }\
    \n  }\
    \n}\
    \n" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-time=startup
}

# --- Reset Daily Income ---
:if ([/system scheduler find name="Reset Daily Income"] = "") do={
/system scheduler add name="Reset Daily Income" interval=6h on-event=":local sntpStat\
    us [/system ntp client get last-update-from];\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    :local currentDate [/system clock get date];\
    \n    :local currentday [:pick \$currentDate 4 6];\
    \n    :local schedulerID [/system scheduler find name=\"Reset Daily Income\
    \"];\
    \n    :local schedulerComment [/system scheduler get \$schedulerID comment\
    ];\
    \n\
    \n    :if (\$schedulerComment != \$currentday) do={\
    \n        :local todayIncomeSource [/system script get [find name=\"todayi\
    ncome\"] source];\
    \n        /system script set source=\"0\" [find name=\"todayincome\"];\
    \n        /system scheduler set \$schedulerID comment=\"\$currentday\";\
    \n\
    \n        :if (\$todayIncomeSource != \"0\") do={\
    \n            :local isTelegram [:tonum [/system script get [find name=\"e\
    nabletelegram\"] source]];\
    \n            :local isDiscord [:tonum [/system script get [find name=\"en\
    ablediscord\"] source]];\
    \n            :local message (\"The%20income%20today%20is:%20\" . \$todayI\
    ncomeSource);\
    \n\
    \n            :if (\$isTelegram = 1) do={\
    \n                :local iTBotToken [/system script get [find name=\"botto\
    ken\"] source];\
    \n                :local iTGrChatID [/system script get [find name=\"chati\
    d\"] source];\
    \n                :do {\
    \n                    /tool fetch url=(\"https://api.telegram.org/bot\" . \
    \$iTBotToken . \"/sendMessage\") \\\
    \n                        http-method=post \\\
    \n                        http-data=(\"chat_id=\" . \$iTGrChatID . \"&text\
    =\" . \$message) \\\
    \n                        keep-result=no;\
    \n                } on-error={ :log warning \"resetdaily: Telegram send fa\
    iled\"; }\
    \n            }\
    \n\
    \n            :delay 1s;\
    \n\
    \n            :if (\$isDiscord = 1) do={\
    \n                :local iDiscordWebhook [/system script get [find name=\"\
    discordwebhook\"] source];\
    \n                :do {\
    \n                    /tool fetch url=\$iDiscordWebhook http-method=post \
    \\\
    \n                        http-data=(\"content=\" . \"%60%60%60\" . \$mess\
    age . \"%60%60%60%0A** **\") \\\
    \n                        mode=https keep-result=no;\
    \n                } on-error={ :log warning \"resetdaily: Discord send fai\
    led\"; }\
    \n            }\
    \n        }\
    \n    }\
    \n}" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=sep/28/2021 start-time=00:00:01
} else={
/system scheduler set [find name="Reset Daily Income"] interval=6h on-event=":local sntpStat\
    us [/system ntp client get last-update-from];\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    :local currentDate [/system clock get date];\
    \n    :local currentday [:pick \$currentDate 4 6];\
    \n    :local schedulerID [/system scheduler find name=\"Reset Daily Income\
    \"];\
    \n    :local schedulerComment [/system scheduler get \$schedulerID comment\
    ];\
    \n\
    \n    :if (\$schedulerComment != \$currentday) do={\
    \n        :local todayIncomeSource [/system script get [find name=\"todayi\
    ncome\"] source];\
    \n        /system script set source=\"0\" [find name=\"todayincome\"];\
    \n        /system scheduler set \$schedulerID comment=\"\$currentday\";\
    \n\
    \n        :if (\$todayIncomeSource != \"0\") do={\
    \n            :local isTelegram [:tonum [/system script get [find name=\"e\
    nabletelegram\"] source]];\
    \n            :local isDiscord [:tonum [/system script get [find name=\"en\
    ablediscord\"] source]];\
    \n            :local message (\"The%20income%20today%20is:%20\" . \$todayI\
    ncomeSource);\
    \n\
    \n            :if (\$isTelegram = 1) do={\
    \n                :local iTBotToken [/system script get [find name=\"botto\
    ken\"] source];\
    \n                :local iTGrChatID [/system script get [find name=\"chati\
    d\"] source];\
    \n                :do {\
    \n                    /tool fetch url=(\"https://api.telegram.org/bot\" . \
    \$iTBotToken . \"/sendMessage\") \\\
    \n                        http-method=post \\\
    \n                        http-data=(\"chat_id=\" . \$iTGrChatID . \"&text\
    =\" . \$message) \\\
    \n                        keep-result=no;\
    \n                } on-error={ :log warning \"resetdaily: Telegram send fa\
    iled\"; }\
    \n            }\
    \n\
    \n            :delay 1s;\
    \n\
    \n            :if (\$isDiscord = 1) do={\
    \n                :local iDiscordWebhook [/system script get [find name=\"\
    discordwebhook\"] source];\
    \n                :do {\
    \n                    /tool fetch url=\$iDiscordWebhook http-method=post \
    \\\
    \n                        http-data=(\"content=\" . \"%60%60%60\" . \$mess\
    age . \"%60%60%60%0A** **\") \\\
    \n                        mode=https keep-result=no;\
    \n                } on-error={ :log warning \"resetdaily: Discord send fai\
    led\"; }\
    \n            }\
    \n        }\
    \n    }\
    \n}" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=sep/28/2021 start-time=00:00:01
}

# --- reset maxactiveusers ---
:if ([/system scheduler find name="reset maxactiveusers"] = "") do={
/system scheduler add name="reset maxactiveusers" interval=6h on-event=":local sntpSt\
    atus [/system ntp client get last-update-from];\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    :local currentDate [/system clock get date];\
    \n    :local currentday [:pick \$currentDate 4 6];\
    \n    :local schedulerID [/system scheduler find name=\"reset maxactiveuse\
    rs\"];\
    \n    :local schedulerComment [/system scheduler get \$schedulerID comment\
    ];\
    \n\
    \n    :if (\$schedulerComment != \$currentday) do={\
    \n        :local currentSource [/system script get [find name=\"maxactiveu\
    sers\"] source];\
    \n        /system script set [find name=\"maxactiveusers\"] source=\"0\";\
    \n        /system scheduler set \$schedulerID comment=\"\$currentday\";\
    \n\
    \n        :if (\$currentSource != \"0\") do={\
    \n            :local isTelegram [:tonum [/system script get [find name=\"e\
    nabletelegram\"] source]];\
    \n            :local isDiscord [:tonum [/system script get [find name=\"en\
    ablediscord\"] source]];\
    \n            :local message (\"The%20top%20active%20users%20for%20today%2\
    0is:%20\" . \$currentSource);\
    \n\
    \n            :if (\$isTelegram = 1) do={\
    \n                :local iTBotToken [/system script get [find name=\"botto\
    ken\"] source];\
    \n                :local iTGrChatID [/system script get [find name=\"chati\
    d\"] source];\
    \n                :do {\
    \n                    /tool fetch url=(\"https://api.telegram.org/bot\" . \
    \$iTBotToken . \"/sendMessage\") \\\
    \n                        http-method=post \\\
    \n                        http-data=(\"chat_id=\" . \$iTGrChatID . \"&text\
    =\" . \$message) \\\
    \n                        keep-result=no;\
    \n                } on-error={ :log warning \"resetmaxactiveusers: Telegra\
    m send failed\"; }\
    \n            }\
    \n\
    \n            :delay 1s;\
    \n\
    \n            :if (\$isDiscord = 1) do={\
    \n                :local iDiscordWebhook [/system script get [find name=\"\
    discordwebhook\"] source];\
    \n                :do {\
    \n                    /tool fetch url=\$iDiscordWebhook http-method=post \
    \\\
    \n                        http-data=(\"content=\" . \"%60%60%60\" . \$mess\
    age . \"%60%60%60%0A** **\") \\\
    \n                        mode=https keep-result=no;\
    \n                } on-error={ :log warning \"resetmaxactiveusers: Discord\
    \_send failed\"; }\
    \n            }\
    \n        }\
    \n    }\
    \n}" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=feb/16/2025 start-time=00:00:01
} else={
/system scheduler set [find name="reset maxactiveusers"] interval=6h on-event=":local sntpSt\
    atus [/system ntp client get last-update-from];\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    :local currentDate [/system clock get date];\
    \n    :local currentday [:pick \$currentDate 4 6];\
    \n    :local schedulerID [/system scheduler find name=\"reset maxactiveuse\
    rs\"];\
    \n    :local schedulerComment [/system scheduler get \$schedulerID comment\
    ];\
    \n\
    \n    :if (\$schedulerComment != \$currentday) do={\
    \n        :local currentSource [/system script get [find name=\"maxactiveu\
    sers\"] source];\
    \n        /system script set [find name=\"maxactiveusers\"] source=\"0\";\
    \n        /system scheduler set \$schedulerID comment=\"\$currentday\";\
    \n\
    \n        :if (\$currentSource != \"0\") do={\
    \n            :local isTelegram [:tonum [/system script get [find name=\"e\
    nabletelegram\"] source]];\
    \n            :local isDiscord [:tonum [/system script get [find name=\"en\
    ablediscord\"] source]];\
    \n            :local message (\"The%20top%20active%20users%20for%20today%2\
    0is:%20\" . \$currentSource);\
    \n\
    \n            :if (\$isTelegram = 1) do={\
    \n                :local iTBotToken [/system script get [find name=\"botto\
    ken\"] source];\
    \n                :local iTGrChatID [/system script get [find name=\"chati\
    d\"] source];\
    \n                :do {\
    \n                    /tool fetch url=(\"https://api.telegram.org/bot\" . \
    \$iTBotToken . \"/sendMessage\") \\\
    \n                        http-method=post \\\
    \n                        http-data=(\"chat_id=\" . \$iTGrChatID . \"&text\
    =\" . \$message) \\\
    \n                        keep-result=no;\
    \n                } on-error={ :log warning \"resetmaxactiveusers: Telegra\
    m send failed\"; }\
    \n            }\
    \n\
    \n            :delay 1s;\
    \n\
    \n            :if (\$isDiscord = 1) do={\
    \n                :local iDiscordWebhook [/system script get [find name=\"\
    discordwebhook\"] source];\
    \n                :do {\
    \n                    /tool fetch url=\$iDiscordWebhook http-method=post \
    \\\
    \n                        http-data=(\"content=\" . \"%60%60%60\" . \$mess\
    age . \"%60%60%60%0A** **\") \\\
    \n                        mode=https keep-result=no;\
    \n                } on-error={ :log warning \"resetmaxactiveusers: Discord\
    \_send failed\"; }\
    \n            }\
    \n        }\
    \n    }\
    \n}" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=feb/16/2025 start-time=00:00:01
}

# --- resetmonthly ---
:if ([/system scheduler find name="resetmonthly"] = "") do={
/system scheduler add name="resetmonthly" interval=6h on-event=":local sntpStatus [/sy\
    stem ntp client get last-update-from];\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    :local currentDate [/system clock get date];\
    \n    :local currentMonth [:pick \$currentDate 0 3];\
    \n    :local schedulerID [/system scheduler find name=\"resetmonthly\"];\
    \n    :local schedulerComment [/system scheduler get \$schedulerID comment\
    ];\
    \n\
    \n    :if (\$schedulerComment != \$currentMonth) do={\
    \n        :local monthlyIncomeSource [/system script get [find name=\"mont\
    hlyincome\"] source];\
    \n        /system script set source=\"0\" [find name=\"monthlyincome\"];\
    \n        /system scheduler set \$schedulerID comment=\"\$currentMonth\";\
    \n\
    \n        :if (\$monthlyIncomeSource != \"0\") do={\
    \n            :local isTelegram [:tonum [/system script get [find name=\"e\
    nabletelegram\"] source]];\
    \n            :local isDiscord [:tonum [/system script get [find name=\"en\
    ablediscord\"] source]];\
    \n            :local message (\"The%20income%20for%20this%20month%20is:%20\
    \" . \$monthlyIncomeSource);\
    \n\
    \n            :if (\$isTelegram = 1) do={\
    \n                :local iTBotToken [/system script get [find name=\"botto\
    ken\"] source];\
    \n                :local iTGrChatID [/system script get [find name=\"chati\
    d\"] source];\
    \n                :do {\
    \n                    /tool fetch url=(\"https://api.telegram.org/bot\" . \
    \$iTBotToken . \"/sendMessage\") \\\
    \n                        http-method=post \\\
    \n                        http-data=(\"chat_id=\" . \$iTGrChatID . \"&text\
    =\" . \$message) \\\
    \n                        keep-result=no;\
    \n                } on-error={ :log warning \"resetmonthly: Telegram send \
    failed\"; }\
    \n            }\
    \n\
    \n            :delay 1s;\
    \n\
    \n            :if (\$isDiscord = 1) do={\
    \n                :local iDiscordWebhook [/system script get [find name=\"\
    discordwebhook\"] source];\
    \n                :do {\
    \n                    /tool fetch url=\$iDiscordWebhook http-method=post \
    \\\
    \n                        http-data=(\"content=\" . \"%60%60%60\" . \$mess\
    age . \"%60%60%60%0A** **\") \\\
    \n                        mode=https keep-result=no;\
    \n                } on-error={ :log warning \"resetmonthly: Discord send f\
    ailed\"; }\
    \n            }\
    \n        }\
    \n    }\
    \n}" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=mar/24/2025 start-time=00:00:01
} else={
/system scheduler set [find name="resetmonthly"] interval=6h on-event=":local sntpStatus [/sy\
    stem ntp client get last-update-from];\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    :local currentDate [/system clock get date];\
    \n    :local currentMonth [:pick \$currentDate 0 3];\
    \n    :local schedulerID [/system scheduler find name=\"resetmonthly\"];\
    \n    :local schedulerComment [/system scheduler get \$schedulerID comment\
    ];\
    \n\
    \n    :if (\$schedulerComment != \$currentMonth) do={\
    \n        :local monthlyIncomeSource [/system script get [find name=\"mont\
    hlyincome\"] source];\
    \n        /system script set source=\"0\" [find name=\"monthlyincome\"];\
    \n        /system scheduler set \$schedulerID comment=\"\$currentMonth\";\
    \n\
    \n        :if (\$monthlyIncomeSource != \"0\") do={\
    \n            :local isTelegram [:tonum [/system script get [find name=\"e\
    nabletelegram\"] source]];\
    \n            :local isDiscord [:tonum [/system script get [find name=\"en\
    ablediscord\"] source]];\
    \n            :local message (\"The%20income%20for%20this%20month%20is:%20\
    \" . \$monthlyIncomeSource);\
    \n\
    \n            :if (\$isTelegram = 1) do={\
    \n                :local iTBotToken [/system script get [find name=\"botto\
    ken\"] source];\
    \n                :local iTGrChatID [/system script get [find name=\"chati\
    d\"] source];\
    \n                :do {\
    \n                    /tool fetch url=(\"https://api.telegram.org/bot\" . \
    \$iTBotToken . \"/sendMessage\") \\\
    \n                        http-method=post \\\
    \n                        http-data=(\"chat_id=\" . \$iTGrChatID . \"&text\
    =\" . \$message) \\\
    \n                        keep-result=no;\
    \n                } on-error={ :log warning \"resetmonthly: Telegram send \
    failed\"; }\
    \n            }\
    \n\
    \n            :delay 1s;\
    \n\
    \n            :if (\$isDiscord = 1) do={\
    \n                :local iDiscordWebhook [/system script get [find name=\"\
    discordwebhook\"] source];\
    \n                :do {\
    \n                    /tool fetch url=\$iDiscordWebhook http-method=post \
    \\\
    \n                        http-data=(\"content=\" . \"%60%60%60\" . \$mess\
    age . \"%60%60%60%0A** **\") \\\
    \n                        mode=https keep-result=no;\
    \n                } on-error={ :log warning \"resetmonthly: Discord send f\
    ailed\"; }\
    \n            }\
    \n        }\
    \n    }\
    \n}" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=mar/24/2025 start-time=00:00:01
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
/system scheduler add name="reset yearly" interval=6h on-event=":local sntpStatus [\
    /system ntp client get last-update-from];\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    :local currentDate [/system clock get date];\
    \n    :local currentyear [:pick \$currentDate 7 11];\
    \n    :local schedulerID [/system scheduler find name=\"reset yearly\"];\
    \n    :local schedulerComment [/system scheduler get \$schedulerID comment\
    ];\
    \n\
    \n    :if (\$schedulerComment != \$currentyear) do={\
    \n        :local yearlyIncomeSource [/system script get [find name=\"yearl\
    yincome\"] source];\
    \n        /system script set source=\"0\" [find name=\"yearlyincome\"];\
    \n        /system scheduler set \$schedulerID comment=\"\$currentyear\";\
    \n\
    \n        :if (\$yearlyIncomeSource != \"0\") do={\
    \n            :local isTelegram [:tonum [/system script get [find name=\"e\
    nabletelegram\"] source]];\
    \n            :local isDiscord [:tonum [/system script get [find name=\"en\
    ablediscord\"] source]];\
    \n            :local message (\"The%20income%20for%20this%20year%20is:%20\
    \" . \$yearlyIncomeSource);\
    \n\
    \n            :if (\$isTelegram = 1) do={\
    \n                :local iTBotToken [/system script get [find name=\"botto\
    ken\"] source];\
    \n                :local iTGrChatID [/system script get [find name=\"chati\
    d\"] source];\
    \n                :do {\
    \n                    /tool fetch url=(\"https://api.telegram.org/bot\" . \
    \$iTBotToken . \"/sendMessage\") \\\
    \n                        http-method=post \\\
    \n                        http-data=(\"chat_id=\" . \$iTGrChatID . \"&text\
    =\" . \$message) \\\
    \n                        keep-result=no;\
    \n                } on-error={ :log warning \"resetyearly: Telegram send f\
    ailed\"; }\
    \n            }\
    \n\
    \n            :delay 1s;\
    \n\
    \n            :if (\$isDiscord = 1) do={\
    \n                :local iDiscordWebhook [/system script get [find name=\"\
    discordwebhook\"] source];\
    \n                :do {\
    \n                    /tool fetch url=\$iDiscordWebhook http-method=post \
    \\\
    \n                        http-data=(\"content=\" . \"%60%60%60\" . \$mess\
    age . \"%60%60%60%0A** **\") \\\
    \n                        mode=https keep-result=no;\
    \n                } on-error={ :log warning \"resetyearly: Discord send fa\
    iled\"; }\
    \n            }\
    \n        }\
    \n    }\
    \n}" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jan/02/1970 start-time=00:00:01
} else={
/system scheduler set [find name="reset yearly"] interval=6h on-event=":local sntpStatus [\
    /system ntp client get last-update-from];\
    \n:if ([:len \$sntpStatus] > 0) do={\
    \n    :local currentDate [/system clock get date];\
    \n    :local currentyear [:pick \$currentDate 7 11];\
    \n    :local schedulerID [/system scheduler find name=\"reset yearly\"];\
    \n    :local schedulerComment [/system scheduler get \$schedulerID comment\
    ];\
    \n\
    \n    :if (\$schedulerComment != \$currentyear) do={\
    \n        :local yearlyIncomeSource [/system script get [find name=\"yearl\
    yincome\"] source];\
    \n        /system script set source=\"0\" [find name=\"yearlyincome\"];\
    \n        /system scheduler set \$schedulerID comment=\"\$currentyear\";\
    \n\
    \n        :if (\$yearlyIncomeSource != \"0\") do={\
    \n            :local isTelegram [:tonum [/system script get [find name=\"e\
    nabletelegram\"] source]];\
    \n            :local isDiscord [:tonum [/system script get [find name=\"en\
    ablediscord\"] source]];\
    \n            :local message (\"The%20income%20for%20this%20year%20is:%20\
    \" . \$yearlyIncomeSource);\
    \n\
    \n            :if (\$isTelegram = 1) do={\
    \n                :local iTBotToken [/system script get [find name=\"botto\
    ken\"] source];\
    \n                :local iTGrChatID [/system script get [find name=\"chati\
    d\"] source];\
    \n                :do {\
    \n                    /tool fetch url=(\"https://api.telegram.org/bot\" . \
    \$iTBotToken . \"/sendMessage\") \\\
    \n                        http-method=post \\\
    \n                        http-data=(\"chat_id=\" . \$iTGrChatID . \"&text\
    =\" . \$message) \\\
    \n                        keep-result=no;\
    \n                } on-error={ :log warning \"resetyearly: Telegram send f\
    ailed\"; }\
    \n            }\
    \n\
    \n            :delay 1s;\
    \n\
    \n            :if (\$isDiscord = 1) do={\
    \n                :local iDiscordWebhook [/system script get [find name=\"\
    discordwebhook\"] source];\
    \n                :do {\
    \n                    /tool fetch url=\$iDiscordWebhook http-method=post \
    \\\
    \n                        http-data=(\"content=\" . \"%60%60%60\" . \$mess\
    age . \"%60%60%60%0A** **\") \\\
    \n                        mode=https keep-result=no;\
    \n                } on-error={ :log warning \"resetyearly: Discord send fa\
    iled\"; }\
    \n            }\
    \n        }\
    \n    }\
    \n}" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jan/02/1970 start-time=00:00:01
}



/ip hotspot user profile
set [ find default=yes ] add-mac-cookie=no keepalive-timeout=3m name=\
    autospeedlimit on-login="\
    \n# ============================================================\
    \n# Hotspot Login Script (Optimized for hAP lite)\
    \n# ============================================================\
    \n\
    \n# --- Clock ---\
    \n:local date [/system clock get date];\
    \n:local time [/system clock get time];\
    \n\
    \n# --- Interface Throughput (Note: This delays login by exactly 1 second)\
    \_---\
    \n:local ifName \"ether1\";\
    \n:local rxBps 0; :local txBps 0;\
    \n/interface monitor-traffic \$ifName once do={\
    \n    :set rxBps \$\"rx-bits-per-second\";\
    \n    :set txBps \$\"tx-bits-per-second\";\
    \n}\
    \n:local rxKbps (\$rxBps / 1000);\
    \n:local txKbps (\$txBps / 1000);\
    \n:local rxStr \"0 Kbps\"; :local txStr \"0 Kbps\";\
    \n\
    \n:if (\$rxKbps >= 1000) do={ :set rxStr ((\$rxKbps / 1000) . \".\" . ((\$\
    rxKbps % 1000) / 100) . \" Mbps\"); } else={ :set rxStr (\"\$rxKbps Kbps\"\
    ); }\
    \n:if (\$txKbps >= 1000) do={ :set txStr ((\$txKbps / 1000) . \".\" . ((\$\
    txKbps % 1000) / 100) . \" Mbps\"); } else={ :set txStr (\"\$txKbps Kbps\"\
    ); }\
    \n:local queueRate (\"\$rxStr | \$txStr\");\
    \n\
    \n# --- MAC / Address / Device Name ---\
    \n:local mac \$\"mac-address\";\
    \n:local macNoCol (\"\$[:pick \$mac 0 2]\$[:pick \$mac 3 5]\$[:pick \$mac \
    6 8]\$[:pick \$mac 9 11]\$[:pick \$mac 12 14]\$[:pick \$mac 15 17]\");\
    \n:local deviceName \"\";\
    \n:local leaseID [/ip dhcp-server lease find mac-address=\$mac];\
    \n:if ([:len \$leaseID] > 0) do={\
    \n    :set deviceName [/ip dhcp-server lease get \$leaseID host-name];\
    \n}\
    \n:if ([:len \$deviceName] = 0) do={ :set deviceName \"N/A\"; }\
    \n\
    \n# --- Hotspot User Info ---\
    \n:local uID [/ip hotspot user find name=\$user];\
    \n:local limit [/ip hotspot user get \$uID limit-uptime];\
    \n:local uptime [/ip hotspot user get \$uID uptime];\
    \n:local com [/ip hotspot user get \$uID comment];\
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
    \n:local freeRam [/system resource get free-memory];\
    \n:local ramMB (\$freeRam / 1048576);\
    \n:local ramdecimal ((\$freeRam % 1048576) / 104858);\
    \n:local uactive [/ip hotspot active print count-only];\
    \n\
    \n# --- Notification Config ---\
    \n:local hotspotFolder \"hotspot\";\
    \n:local isTelegram [:tonum [/system script get [find name=\"enabletelegra\
    m\"] source]];\
    \n:local iTBotToken [/system script get [find name=\"bottoken\"] source];\
    \n:local iTGrChatID [/system script get [find name=\"chatid\"] source];\
    \n:local isDiscord [:tonum [/system script get [find name=\"enablediscord\
    \"] source]];\
    \n:local iDiscordWebhook [/system script get [find name=\"discordwebhook\"\
    ] source];\
    \n\
    \n# --- Sales Tracking ---\
    \n:local todaysales [:tonum [/system script get todayincome source]];\
    \n:local mnthlysales [:tonum [/system script get monthlyincome source]];\
    \n:local yearlysales [:tonum [/system script get yearlyincome source]];\
    \n:local iDailySales (\$iSaleAmt + \$todaysales);\
    \n:local iMonthSales (\$iSaleAmt + \$mnthlysales);\
    \n:local iYearSales (\$iSaleAmt + \$yearlysales);\
    \n\
    \n# --- Update Sales (Only on new purchase) ---\
    \n:if (\$com != \"\") do={\
    \n    /system script set todayincome source=\"\$iDailySales\";\
    \n    /system script set monthlyincome source=\"\$iMonthSales\";\
    \n    /system script set yearlyincome source=\"\$iYearSales\";\
    \n    :set validity [:pick \$com 0 [:find \$com \",\"]];\
    \n}\
    \n\
    \n# --- Resume Notification (Async Execution to avoid freezing login) ---\
    \n:if (\$com = \"\") do={\
    \n    :local rtimeMessage (\"\$user%20resumed%20time,%20remaining%20time%2\
    0is%20\$remainingt%0AActive%20Users:%20\$uactive\");\
    \n    \
    \n    :if (\$isTelegram = 1) do={\
    \n        :local tgCmd \"/tool fetch url=\\\"https://api.telegram.org/bot\
    \$iTBotToken/sendMessage\\\" http-method=post http-data=\\\"chat_id=\$iTGr\
    ChatID&text=\$rtimeMessage\\\" keep-result=no;\";\
    \n        :execute script=\$tgCmd;\
    \n    }\
    \n    :if (\$isDiscord = 1) do={\
    \n        :local dcCmd \"/tool fetch url=\\\"\$iDiscordWebhook\\\" http-me\
    thod=post http-data=\\\"content=```\$rtimeMessage```%0A** **\\\" mode=http\
    s keep-result=no;\";\
    \n        :execute script=\$dcCmd;\
    \n    }\
    \n}\
    \n\
    \n# --- Fix 0m validity (NodeMCU failure fallback) ---\
    \n:global GlobalCachedRates;\
    \n:if (\$validity = \"0m\") do={\
    \n    :local foundValidity \"\"; :local freshRates \"\"; :local minutesCac\
    he \"\";\
    \n    \
    \n    :if ([:len \$GlobalCachedRates] = 0) do={\
    \n        :set GlobalCachedRates [/system script get [find name=\"cachedra\
    tes\"] source];\
    \n    }\
    \n\
    \n    :do { :set freshRates ([/tool fetch url=(\"http://10.0.0.5/getRates\
    \?rateType=1\") output=user as-value]->\"data\") } on-error={}\
    \n\
    \n    :if (\$freshRates != \"\") do={\
    \n        :local newCache \"\"; :local remaining \$freshRates; :local pars\
    ing true;\
    \n        :while (\$parsing = true) do={\
    \n            :local pipeIdx [:find \$remaining \"|\"]; :local entry \"\";\
    \n            :if ([:len [:tostr \$pipeIdx]] > 0) do={\
    \n                :set entry [:pick \$remaining 0 \$pipeIdx];\
    \n                :set remaining [:pick \$remaining (\$pipeIdx + 1) [:len \
    \$remaining]];\
    \n            } else={\
    \n                :set entry \$remaining; :set parsing false;\
    \n            }\
    \n            :if ([:len \$entry] > 0) do={\
    \n                :local p1 [:find \$entry \"#\"]; :local p2 [:find \$entr\
    y \"#\" (\$p1 + 1)];\
    \n                :local p3 [:find \$entry \"#\" (\$p2 + 1)]; :local p4 [:\
    find \$entry \"#\" (\$p3 + 1)];\
    \n                \
    \n                :local eAmt [:tonum [:pick \$entry (\$p1 + 1) \$p2]];\
    \n                :local eValMins [:tonum [:pick \$entry (\$p3 + 1) \$p4]]\
    ;\
    \n\
    \n                :local days (\$eValMins / 1440); :local rem (\$eValMins \
    % 1440);\
    \n                :local hrs (\$rem / 60); :local mins (\$rem % 60);\
    \n                :local hStr [:tostr \$hrs]; :if (\$hrs < 10) do={ :set h\
    Str \"0\$hrs\"; }\
    \n                :local mStr [:tostr \$mins]; :if (\$mins < 10) do={ :set\
    \_mStr \"0\$mins\"; }\
    \n                \
    \n                :local valStr \"\";\
    \n                :if (\$days > 0) do={ :set valStr (\"\$days\" . \"d\$hSt\
    r:\$mStr:00\"); } else={ :set valStr \"\$hStr:\$mStr:00\"; }\
    \n\
    \n                :if (\$newCache != \"\") do={ :set newCache (\$newCache \
    . \",\"); }\
    \n                :set newCache (\$newCache . \"\$eAmt:\$valStr:\$eValMins\
    \");\
    \n\
    \n                :if (\$minutesCache != \"\") do={ :set minutesCache (\$m\
    inutesCache . \",\"); }\
    \n                :set minutesCache (\$minutesCache . \"\$eAmt:\$eValMins\
    \");\
    \n\
    \n                :if (\$eAmt = \$iSaleAmt) do={ :set foundValidity \$valS\
    tr; }\
    \n            }\
    \n        }\
    \n        \
    \n        :if (\$newCache != \$GlobalCachedRates) do={\
    \n            :set GlobalCachedRates \$newCache;\
    \n            /system script set [find name=\"cachedrates\"] source=\$newC\
    ache;\
    \n        }\
    \n    } else={\
    \n        :foreach e in=[:toarray \$GlobalCachedRates] do={\
    \n            :local cp1 [:find \$e \":\"]; :local cp2 [:find \$e \":\" (\
    \$cp1 + 1)];\
    \n            :if ([:len [:tostr \$cp1]] > 0 && [:len [:tostr \$cp2]] > 0)\
    \_do={\
    \n                :local eAmt [:tonum [:pick \$e 0 \$cp1]];\
    \n                :local eVal [:pick \$e (\$cp1 + 1) \$cp2];\
    \n                :local eMinsStored [:tonum [:pick \$e (\$cp2 + 1) [:len \
    \$e]]];\
    \n\
    \n                :if (\$eAmt = \$iSaleAmt) do={ :set foundValidity \$eVal\
    ; }\
    \n                :if (\$minutesCache != \"\") do={ :set minutesCache (\$m\
    inutesCache . \",\"); }\
    \n                :set minutesCache (\$minutesCache . \"\$eAmt:\$eMinsStor\
    ed\");\
    \n            }\
    \n        }\
    \n    }\
    \n\
    \n    :if (\$foundValidity = \"\") do={\
    \n        :local remAmt \$iSaleAmt; :local totalMins 0; :local combined tr\
    ue;\
    \n        :while (\$remAmt > 0 && \$combined = true) do={\
    \n            :set combined false; :local bestAmt 0; :local bestMins 0;\
    \n            :foreach e in=[:toarray \$minutesCache] do={\
    \n                :local cp [:find \$e \":\"]; :local eAmt [:tonum [:pick \
    \$e 0 \$cp]]; :local eMins [:tonum [:pick \$e (\$cp + 1) [:len \$e]]];\
    \n                :if (\$eAmt <= \$remAmt && \$eAmt > \$bestAmt) do={ :set\
    \_bestAmt \$eAmt; :set bestMins \$eMins; }\
    \n            }\
    \n            :if (\$bestAmt > 0) do={\
    \n                :set totalMins (\$totalMins + \$bestMins); :set remAmt (\
    \$remAmt - \$bestAmt); :set combined true;\
    \n            }\
    \n        }\
    \n        :if (\$remAmt = 0 && \$totalMins > 0) do={\
    \n            :local days (\$totalMins / 1440); :local rem (\$totalMins % \
    1440);\
    \n            :local hrs (\$rem / 60); :local mins (\$rem % 60);\
    \n            :local hStr [:tostr \$hrs]; :if (\$hrs < 10) do={ :set hStr \
    \"0\$hrs\"; }\
    \n            :local mStr [:tostr \$mins]; :if (\$mins < 10) do={ :set mSt\
    r \"0\$mins\"; }\
    \n            :if (\$days > 0) do={ :set foundValidity (\"\$days\" . \"d\$\
    hStr:\$mStr:00\"); } else={ :set foundValidity \"\$hStr:\$mStr:00\"; }\
    \n        }\
    \n    }\
    \n    :if (\$foundValidity != \"\") do={ :set validity \$foundValidity; }\
    \n}\
    \n\
    \n# --- Clear comment flag ---\
    \n/ip hotspot user set comment=\"\" \$user;\
    \n\
    \n# --- New Purchase: Scheduler Addition ---\
    \n:if (\$com != \"\") do={\
    \n    :if (\$validity != \"0m\") do={\
    \n        :local sc [/sys scheduler find name=\$user];\
    \n        :if ([:len \$sc] = 0) do={\
    \n            /sys sch add name=\"\$user\" disable=no start-date=\$date in\
    terval=\$validity \\\
    \n                on-event=\"/ip hotspot user remove [find name=\$user]; /\
    ip hotspot active remove [find user=\$user]; /ip hotspot cookie remove [fi\
    nd user=\$user]; /system sche remove [find name=\$user]; /file remove [fin\
    d name=\\\"\$hotspotFolder/data/\$macNoCol.txt\\\"];\" \\\
    \n                policy=ftp,reboot,read,write,policy,test,password,sniff,\
    sensitive,romon;\
    \n            :delay 2s;\
    \n        } else={\
    \n            :local sint [/sys scheduler get \$user interval];\
    \n            :if (\$validity != \"\") do={ /sys scheduler set \$user inte\
    rval (\$sint + \$validity); }\
    \n        }\
    \n    }\
    \n}\
    \n\
    \n# ============================================================\
    \n# --- File Creation Logic (Writes only if New Sale or Missing)\
    \n# ============================================================\
    \n:local targetFile \"\$hotspotFolder/data/\$macNoCol.txt\";\
    \n:local needFileUpdate false;\
    \n\
    \n# Condition 1: New Sale\
    \n:if (\$com != \"\") do={ :set needFileUpdate true; }\
    \n\
    \n# Condition 2: The file doesn't exist in the system anymore\
    \n:if ([:len [/file find name=\$targetFile]] = 0) do={ :set needFileUpdate\
    \_true; }\
    \n\
    \n# Execute write only if needed\
    \n:if (\$needFileUpdate = true) do={\
    \n    :local userSch [/sys scheduler find name=\$user];\
    \n    :local validUntil \"Unlimited\";\
    \n    :if ([:len \$userSch] > 0) do={ :set validUntil [/sys scheduler get \
    \$userSch next-run]; }\
    \n\
    \n    :local fileScheduler \"FILE\$macNoCol\";\
    \n    :if ([:len [/sys scheduler find name=\$fileScheduler]] > 0) do={ \
    \n        /system scheduler remove [find name=\$fileScheduler]; \
    \n    }\
    \n    :do {\
    \n        # Note: RouterOS implicitly adds .txt to 'file print'\
    \n        /system scheduler add name=\"\$fileScheduler\" interval=5 start-\
    time=[/system clock get time] disable=no \\\
    \n            on-event=(\"/system scheduler set \$fileScheduler interval 0\
    ;\\r\\n/file print file=\\\"\$hotspotFolder/data/\$macNoCol\\\" where name\
    =\\\"dummyfile\\\";\\r\\n:delay 1s;\\r\\n/file set \\\"\$targetFile\\\" co\
    ntents=\\\"\$user#\$validUntil\\\";\\r\\n\")\
    \n    } on-error={}\
    \n}\
    \n\
    \n# --- New Purchase: Notification ---\
    \n:if (\$com != \"\") do={\
    \n    # --- Estimates ---\
    \n    :local currentday [:pick \$date 4 6];\
    \n    :local estimatedperday (\$mnthlysales / \$currentday);\
    \n    :local estimatedpermonth (\$estimatedperday * 30);\
    \n    :local iValidUntil [/system scheduler get [find name=\$user] next-ru\
    n];\
    \n\
    \n    # --- Login Notification (Async Execution) ---\
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
    \n    \
    \n    :if (\$isTelegram = 1) do={\
    \n        :local tgCmd \"/tool fetch url=\\\"https://api.telegram.org/bot\
    \$iTBotToken/sendMessage\\\" http-method=post http-data=\\\"chat_id=\$iTGr\
    ChatID&text=\$loginMessage\\\" keep-result=no;\";\
    \n        :execute script=\$tgCmd;\
    \n    }\
    \n    :if (\$isDiscord = 1) do={\
    \n        :local dcCmd \"/tool fetch url=\\\"\$iDiscordWebhook\\\" http-me\
    thod=post http-data=\\\"content=```\$loginMessage```%0A** **\\\" mode=http\
    s keep-result=no;\";\
    \n        :execute script=\$dcCmd;\
    \n    }\
    \n}\
    \n\
    \n# --- Update max active users record safely ---\
    \n:global GlobalMaxActive;\
    \n:if ([:len \$GlobalMaxActive] = 0) do={ :set GlobalMaxActive [/system sc\
    ript get [find name=\"maxactiveusers\"] source]; }\
    \n:if (\$uactive > [:tonum \$GlobalMaxActive]) do={\
    \n    :set GlobalMaxActive \$uactive;\
    \n    /system script set [find name=\"maxactiveusers\"] source=\"\$uactive\
    \";\
    \n}" on-logout="# ========================================================\
    ====\
    \n# Hotspot Logout Script (Optimized for hAP lite - v6 Strict)\
    \n# ============================================================\
    \n\
    \n# --- MAC / Path Setup ---\
    \n:local mac \$\"mac-address\";\
    \n:local macNoCol (\"\$[:pick \$mac 0 2]\$[:pick \$mac 3 5]\$[:pick \$mac \
    6 8]\$[:pick \$mac 9 11]\$[:pick \$mac 12 14]\$[:pick \$mac 15 17]\");\
    \n:local hotspotFolder \"hotspot\";\
    \n\
    \n# --- Notification Config ---\
    \n:local isTelegram [:tonum [/system script get [find name=\"enabletelegra\
    m\"] source]];\
    \n:local isDiscord [:tonum [/system script get [find name=\"enablediscord\
    \"] source]];\
    \n:local iDiscordWebhook [/system script get [find name=\"discordwebhook\"\
    ] source];\
    \n:local iTBotToken [/system script get [find name=\"bottoken\"] source];\
    \n:local iTGrChatID [/system script get [find name=\"chatid\"] source];\
    \n\
    \n# --- Hotspot User Info ---\
    \n:local uID [/ip hotspot user find name=\$user];\
    \n:local com \"\";\
    \n:local uLimit;\
    \n:local uUptime;\
    \n\
    \n:if ([:len \$uID] > 0) do={\
    \n    :set com [/ip hotspot user get \$uID comment];\
    \n    :set uLimit [/ip hotspot user get \$uID limit-uptime];\
    \n    :set uUptime [/ip hotspot user get \$uID uptime];\
    \n}\
    \n\
    \n# --- Expire user safely if time is used up ---\
    \n:local userExpired false;\
    \n:if ([:typeof \$uLimit] = \"time\" && [:typeof \$uUptime] = \"time\") do\
    ={\
    \n    :if (\$uLimit > 0s && \$uLimit <= \$uUptime) do={\
    \n        /ip hotspot user remove [find name=\$user];\
    \n        /file remove [find name=\"\$hotspotFolder/data/\$macNoCol.txt\"]\
    ;\
    \n        /system scheduler remove [find name=\$user];\
    \n        :set userExpired true;\
    \n    }\
    \n}\
    \n\
    \n# --- Clean up background schedulers safely ---\
    \n:local fileScheduler \"FILE\$macNoCol\";\
    \n:if ([:len [/system scheduler find name=\$fileScheduler]] > 0) do={\
    \n    /system scheduler remove [find name=\$fileScheduler];\
    \n}\
    \n\
    \n:local retryScheduler \"RETRY\$macNoCol\";\
    \n:if ([:len [/system scheduler find name=\$retryScheduler]] > 0) do={\
    \n    /system scheduler remove [find name=\$retryScheduler];\
    \n}\
    \n\
    \n# --- Determine Cause & Message ---\
    \n:local notifyMsg \"\";\
    \n\
    \n:if (\$cause = \"session timeout\") do={\
    \n    :set notifyMsg \"\$user%20ran%20out%20of%20time!\";\
    \n} else={\
    \n    :if (\$com = \"\" && \$cause = \"user request\") do={\
    \n        :set notifyMsg \"\$user%20paused%20time.\";\
    \n    } else={\
    \n        :if (\$cause = \"keepalive timeout\") do={\
    \n            :set notifyMsg \"automatically%20paused%20time%20for%20\$use\
    r\";\
    \n        } else={\
    \n            :if (\$cause = \"admin reset\") do={\
    \n                :set notifyMsg \"admin%20kicked%20\$user\";\
    \n            }\
    \n        }\
    \n    }\
    \n}\
    \n\
    \n# --- Send Notifications (Async Background Execution) ---\
    \n:if (\$notifyMsg != \"\") do={\
    \n    :if (\$isTelegram = 1) do={\
    \n        :local tgCmd \"/tool fetch url=\\\"https://api.telegram.org/bot\
    \$iTBotToken/sendMessage\\\" http-method=post http-data=\\\"chat_id=\$iTGr\
    ChatID&text=\$notifyMsg\\\" keep-result=no;\";\
    \n        :execute script=\$tgCmd;\
    \n    }\
    \n    :if (\$isDiscord = 1) do={\
    \n        :local dcCmd \"/tool fetch url=\\\"\$iDiscordWebhook\\\" http-me\
    thod=post http-data=\\\"content=```\$notifyMsg```%0A** **\\\" mode=https k\
    eep-result=no;\";\
    \n        :execute script=\$dcCmd;\
    \n    }\
    \n}\
    \n\
    \n# --- Write session file & Clear Scheduler Comment ---\
    \n# Skip entirely if the user was just expired (ran out of time) \E2\80\94\
    \n# the expire block already deleted their data file; re-creating it\
    \n# would cause a stale \"Unknown\" entry to appear on next login.\
    \n:if ([:len \$uID] > 0 && !\$userExpired) do={\
    \n    :local userSch [/system scheduler find name=\$user];\
    \n    :local iValidUntil \"Unlimited\";\
    \n    \
    \n    :if ([:len \$userSch] > 0) do={ \
    \n        :set iValidUntil [/system scheduler get \$userSch next-run]; \
    \n        /system scheduler set \$userSch comment=\"\";\
    \n    }\
    \n\
    \n    :local myfile \"\$hotspotFolder/data/\$macNoCol.txt\";\
    \n    \
    \n    :if ([:len [/file find name=\$myfile]] = 0) do={\
    \n        :if ([:len \$userSch] = 0) do={\
    \n            :set iValidUntil \"Unknown\";\
    \n        }\
    \n        :local fileCmd \"/file print file=\\\"\$hotspotFolder/data/\$mac\
    NoCol\\\" where name=\\\"dummyfile\\\"; :delay 1s; /file set \\\"\$myfile\
    \\\" contents=\\\"\$user#\$iValidUntil\\\";\";\
    \n        :execute script=\$fileCmd;\
    \n    }\
    \n}" shared-users=2



:log info "done";
