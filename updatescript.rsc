# ==========================================
# Hotspot Full Sync from GitHub
# ==========================================
:local profileName "default"
:local userprofilescript    "https://raw.githubusercontent.com/lmepisowifi/mikrotiklmepisowifi/refs/heads/main/userprofilescript.rsc"
:local loginFile   "gh-on-login.rsc"
:local logoutFile  "gh-on-logout.rsc"
:local ghBase            "https://raw.githubusercontent.com/lmepisowifi/mikrotiklmepisowifi/main"
:local ghHotspotBase     ($ghBase . "/hotspot")
:local ghOptionsUrl      ($ghBase . "/options.txt")
:local localVersionFile  "hotspot/version.txt"
:local localConfigJs     "hotspot/assets/js/config.js"
:local localDataPath     "hotspot/data/"
:local configJsExists false
:local mainPic "hotspot/assets/MainPic.PNG"
:local mainPicExists false
:local insertCoinBg "hotspot/assets/insertcoinbg.mp3"
:local coinReceived "hotspot/assets/coin-received.mp3"
:local insertCoinBgExists false
:local coinReceivedExists false
:do {
    /file get [find name=$insertCoinBg] size
    :set insertCoinBgExists true
} on-error={}
:do {
    /file get [find name=$coinReceived] size
    :set coinReceivedExists true
} on-error={}
:do {
    /file get [find name=$mainPic] size
    :set mainPicExists true
} on-error={}
:do {
    /file get [find name=$localConfigJs] contents
    :set configJsExists true
} on-error={}

# --- Notification Config ---
:local isTelegram      [:tonum [/system script get [find name="enabletelegram"] source]];
:local isDiscord       [:tonum [/system script get [find name="enablediscord"] source]];
:local iDiscordWebhook [/system script get [find name="discordwebhook"] source];
:local iTBotToken      [/system script get [find name="bottoken"] source];
:local iTGrChatID      [/system script get [find name="chatid"] source];


# ==========================================
# PART 1: FETCH & PARSE OPTIONS.TXT
# ==========================================

:local disableHtmlUpdate "false";
:local changelog         "[lmepisowifi] updated.";

:do { /file remove [find name="hs-options.txt"] } on-error={}
:do {
    /tool fetch url=$ghOptionsUrl dst-path="hs-options.txt";
    :local optSz [/file get [find name="hs-options.txt"] size];
    :if ($optSz > 0) do={
        :local opt [/file get [find name="hs-options.txt"] contents];

        # --- Parse key helper (inline macro pattern) ---
        # Key: disablehtmlupdate
        :local k1 "disablehtmlupdate=";
        :local p1 [:find $opt $k1];
        :if ([:len [:tostr $p1]] > 0) do={
            :local vs ($p1 + [:len $k1]);
            :local ne [:find $opt "\n" $vs];
            :local rv "";
            :if ([:len [:tostr $ne]] > 0) do={ :set rv [:pick $opt $vs $ne]; } \
            else={ :set rv [:pick $opt $vs [:len $opt]]; }
            :if ([:len $rv] > 0 && [:pick $rv ([:len $rv]-1) [:len $rv]] = "\r") do={
                :set rv [:pick $rv 0 ([:len $rv]-1)];
            }
            :set disableHtmlUpdate $rv;
        }

        # Key: changelog (pipe-separated entries, e.g. "- fix one|- fix two")
        :local k2 "changelog=";
        :local p2 [:find $opt $k2];
        :if ([:len [:tostr $p2]] > 0) do={
            :local vs ($p2 + [:len $k2]);
            :local ne [:find $opt "\n" $vs];
            :local rv "";
            :if ([:len [:tostr $ne]] > 0) do={ :set rv [:pick $opt $vs $ne]; } \
            else={ :set rv [:pick $opt $vs [:len $opt]]; }
            :if ([:len $rv] > 0 && [:pick $rv ([:len $rv]-1) [:len $rv]] = "\r") do={
                :set rv [:pick $rv 0 ([:len $rv]-1)];
            }
            # Replace | with %0A for URL-safe message (works on ROS 6 & 7)
            :local clOut "";
            :local clLen [:len $rv];
            :local ci 0;
            :while ($ci < $clLen) do={
                :local ch [:pick $rv $ci ($ci + 1)];
                :if ($ch = "|") do={
                    :set clOut ($clOut . "%0A");
                } else={
                    :set clOut ($clOut . $ch);
                }
                :set ci ($ci + 1);
            }
            :set changelog $clOut;
        }
    }
    :do { /file remove [find name="hs-options.txt"] } on-error={}
} on-error={
    :log warning "HotspotSync: options.txt fetch failed, using defaults (disablehtmlupdate=false)";
    :do { /file remove [find name="hs-options.txt"] } on-error={}
}

:log info ("Options loaded — disablehtmlupdate=" . $disableHtmlUpdate);


# ==========================================
# PART 2: VERSION CHECK
# ==========================================

:local localVersion ""
:local ghVersion    ""

# ---- Read local version.txt ----
:do {
    :local raw [/file get [find name=$localVersionFile] contents]
    :set localVersion $raw
    # Strip trailing \r and \n robustly
    :while ([:len $localVersion] > 0 && \
            ([:pick $localVersion ([:len $localVersion]-1) [:len $localVersion]] = "\n" || \
             [:pick $localVersion ([:len $localVersion]-1) [:len $localVersion]] = "\r")) do={
        :set localVersion [:pick $localVersion 0 ([:len $localVersion]-1)]
    }
    :if ($localVersion = "") do={ :set localVersion "0.0.0" }
} on-error={
    :set localVersion "0.0.0"
    :log warning "HotspotSync: No local version.txt found, treating as outdated"
}

# ---- Fetch GitHub version.txt (infinite retry) ----
:local vDone false
:local vAttempt 0
:while (!$vDone) do={
    :set vAttempt ($vAttempt + 1)
    :do { /file remove [find name="hs-gh-version.txt"] } on-error={}
    :do {
        /tool fetch url=($ghHotspotBase . "/version.txt") dst-path="hs-gh-version.txt"
        :local dlSize [/file get [find name="hs-gh-version.txt"] size]
        :if ($dlSize = 0) do={ :error "Empty file" }
# (inside the vDone fetch block, replace the ghVersion stripping)
        :local raw [/file get [find name="hs-gh-version.txt"] contents]
        :set ghVersion $raw
        :while ([:len $ghVersion] > 0 && \
                ([:pick $ghVersion ([:len $ghVersion]-1) [:len $ghVersion]] = "\n" || \
                 [:pick $ghVersion ([:len $ghVersion]-1) [:len $ghVersion]] = "\r")) do={
            :set ghVersion [:pick $ghVersion 0 ([:len $ghVersion]-1)]
        }
        :if ($ghVersion = "") do={ :error "Empty version string" }
        :do { /file remove [find name="hs-gh-version.txt"] } on-error={}
        :set vDone true
    } on-error={
        :log warning ("HotspotSync: version.txt fetch failed, attempt " . $vAttempt . ", retrying in 2s...")
        :put ("version.txt retry " . $vAttempt . " in 2s...")
        :do { /file remove [find name="hs-gh-version.txt"] } on-error={}
        :delay 2s
    }
}

:put ("HTML local: v" . $localVersion . " | GitHub: v" . $ghVersion)

:if ($localVersion = $ghVersion) do={
    :log info ("HotspotSync: HTML is up to date (v" . $ghVersion . ")")
    :put "HTML: up to date"
}

:if ($localVersion != $ghVersion) do={
    :log info ("HotspotSync: HTML update " . $localVersion . " -> " . $ghVersion)

    # ==========================================
    # PHASE 2+3: HTML DELETE + DOWNLOAD
    # Skipped if disablehtmlupdate=true in options.txt
    # ==========================================

    :if ($disableHtmlUpdate != "true") do={

        # Pass 1: delete all non-directory files (skip hotspot/data/)
        :foreach f in=[/file find where name~"^hotspot/"] do={
            :local ftype [/file get $f type]
            :local fname [/file get $f name]
            :if ($ftype != "directory" && !($fname ~ "^hotspot/data/") && \
                 $fname != $localConfigJs && \
                 $fname != $mainPic && \
                 $fname != $insertCoinBg && \
                 $fname != $coinReceived) do={
                :do { /file remove $f } on-error={}
            }
        }
        # Pass 2: delete leftover empty directories
        :local dirPass 0
        :while ($dirPass < 6) do={
            :foreach f in=[/file find where name~"^hotspot/"] do={
                :local fname [/file get $f name]
                :if (!($fname ~ "^hotspot/data") && \
                     $fname != "hotspot/assets" && \
                     $fname != "hotspot/assets/js" && \
                     $fname != $localConfigJs && \
                     $fname != $mainPic && \
                     $fname != $insertCoinBg && \
                     $fname != $coinReceived) do={
                    :do { /file remove $f } on-error={}
                }
            }
            :set dirPass ($dirPass + 1)
        }
        :put "Old hotspot files deleted (data/ preserved)"

        # Fetch manifest.txt (infinite retry)
        :local manifest  ""
        :local manifestOk false
        :local mDone false
        :local mAttempt 0
        :while (!$mDone) do={
            :set mAttempt ($mAttempt + 1)
            :do { /file remove [find name="hs-manifest.txt"] } on-error={}
            :do {
                /tool fetch url=($ghHotspotBase . "/manifest.txt") dst-path="hs-manifest.txt"
                :local dlSize [/file get [find name="hs-manifest.txt"] size]
                :if ($dlSize = 0) do={ :error "Empty file" }
                :set manifest [/file get [find name="hs-manifest.txt"] contents]
                :do { /file remove [find name="hs-manifest.txt"] } on-error={}
                :set manifestOk true
                :set mDone true
            } on-error={
                :log warning ("HotspotSync: manifest.txt fetch failed, attempt " . $mAttempt . ", retrying in 2s...")
                :put ("manifest.txt retry " . $mAttempt . " in 2s...")
                :do { /file remove [find name="hs-manifest.txt"] } on-error={}
                :delay 2s
            }
        }

        :if ($manifestOk) do={
            :local pos    0
            :local line   ""
            :local mlen   [:len $manifest]
            :local dlOk   0
            :local dlFail 0

            :while ($pos < $mlen) do={
                :local ch [:pick $manifest $pos ($pos + 1)]
                :if ($ch = "\n" || $pos = ($mlen - 1)) do={
                    :if ($pos = ($mlen - 1) && $ch != "\n") do={
                        :set line ($line . $ch)
                    }
                    :if ([:len $line] > 0 && [:pick $line ([:len $line]-1) [:len $line]] = "\r") do={
                        :set line [:pick $line 0 ([:len $line]-1)]
                    }
                    :if ([:len $line] > 0 && \
                         (("hotspot/" . $line) != $localConfigJs || !$configJsExists) && \
                         (("hotspot/" . $line) != $mainPic || !$mainPicExists) && \
                         (("hotspot/" . $line) != $insertCoinBg || !$insertCoinBgExists) && \
                         (("hotspot/" . $line) != $coinReceived || !$coinReceivedExists)) do={
                        :local dlUrl ($ghHotspotBase . "/" . $line)
                        :local dlDst ("hotspot/" . $line)
                        :local dlDone false
                        :local dlAttempt 0
                        :while (!$dlDone) do={
                            :set dlAttempt ($dlAttempt + 1)
                            :do { /file remove [find name=$dlDst] } on-error={}
                            :do {
                                /tool fetch url=$dlUrl dst-path=$dlDst
                                :set dlOk ($dlOk + 1)
                                :set dlDone true
                                :log info ("HotspotSync: Downloaded " . $line . " (attempt " . $dlAttempt . ")")
                            } on-error={
                                :log warning ("HotspotSync: Failed " . $line . " attempt " . $dlAttempt . ", retrying in 2s...")
                                :put ("Retry " . $dlAttempt . ": " . $line . " - waiting 2s")
                                :do { /file remove [find name=$dlDst] } on-error={}
                                :delay 2s
                            }
                        }
                    }
                    :set line ""
                } else={
                    :set line ($line . $ch)
                }
                :set pos ($pos + 1)
            }
            :put ("Downloaded: " . $dlOk . " OK, " . $dlFail . " failed")
            :log info ("HotspotSync: HTML updated to v" . $ghVersion)
            :put ("HTML: UPDATED to v" . $ghVersion)
        }

    } else={
        :log info "HotspotSync: HTML update skipped (disablehtmlupdate=true in options.txt)";
        :put "HTML update: SKIPPED (disabled via options.txt)";
    }

    # ==========================================
    # PHASE 4: RUN USERPROFILESCRIPT
    # Always runs on version change, even if HTML update was skipped,
    # because it manages schedulers and system scripts.
    # ==========================================
    :local upsDone false
    :local upsAttempt 0
    :while (!$upsDone) do={
        :set upsAttempt ($upsAttempt + 1)
        :do { /file remove [find name="hs-userprofile.rsc"] } on-error={}
        :do {
            /tool fetch url=$userprofilescript dst-path="hs-userprofile.rsc"
            :local upsSize [/file get [find name="hs-userprofile.rsc"] size]
            :if ($upsSize = 0) do={ :error "Empty file" }
            :log info "HotspotSync: Running userprofilescript after update..."
            /import file-name="hs-userprofile.rsc"
            :do { /file remove [find name="hs-userprofile.rsc"] } on-error={}
            :set upsDone true
            :put "userprofilescript: applied"
        } on-error={
            :log warning ("HotspotSync: userprofilescript fetch/run failed, attempt " . $upsAttempt . ", retrying in 2s...")
            :put ("userprofilescript retry " . $upsAttempt . " in 2s...")
            :do { /file remove [find name="hs-userprofile.rsc"] } on-error={}
            :delay 2s
        }
    }

# ==========================================
    # PHASE 5: SEND UPDATE NOTIFICATION
    # ==========================================
    :local Message ("%5Blmepisowifi%5D%20updated%20to%20v" . $ghVersion . "%0A%0AChangelog:%0A" . $changelog);

    :if ($isTelegram = 1) do={
        :do {
            /tool fetch url=("https://api.telegram.org/bot" . $iTBotToken . "/sendMessage") \
                http-method=post \
                http-data=("chat_id=" . $iTGrChatID . "&text=" . $Message) \
                keep-result=no;
        } on-error={ :log warning "HotspotSync: Telegram update notification failed."; }
    }

    :if ($isDiscord = 1) do={
        :do {
            /tool fetch url=$iDiscordWebhook http-method=post \
                http-data=("content=%60%60%60%0A" . $Message . "%0A%60%60%60%0A**%20**") \
                mode=https keep-result=no;
        } on-error={ :log warning "HotspotSync: Discord update notification failed."; }
    }
    # debug
    :log info "$iTBotToken"
    :log info "$iTGrChatID"
    :log info "$iDiscordWebhook"
# ==========================================
    # PHASE 6: WRITE VERSION FILE
    # Uses fetch dst-path as primary so RouterOS creates
    # hotspot/ directory automatically if it doesn't exist
    # (happens when disablehtmlupdate=true on first run).
    # ==========================================
    :local vWriteDone false;

    :do { /file remove [find name=$localVersionFile] } on-error={}
    :do {
        /tool fetch url=($ghHotspotBase . "/version.txt") dst-path=$localVersionFile;
        :set vWriteDone true;
        :log info ("HotspotSync: version.txt written to " . $ghVersion);
        :put ("Version pinned: " . $ghVersion);
    } on-error={
        :log warning "HotspotSync: version.txt fetch failed, trying manual write...";
    }

    :if (!$vWriteDone) do={
        :do {
            /file print file=$localVersionFile;
            :delay 1s;
            /file set [find name=$localVersionFile] contents=($ghVersion . "\n");
            :set vWriteDone true;
            :log info ("HotspotSync: version.txt manually written to " . $ghVersion);
            :put ("Version pinned (manual): " . $ghVersion);
        } on-error={
            :log error "HotspotSync: CRITICAL — could not write version.txt, update WILL re-trigger next run!";
        }
    }
}
