# ==========================================
# Hotspot Full Sync from GitHub
# ==========================================
:local profileName "default"
:local userprofilescript    "https://raw.githubusercontent.com/lmepisowifi/mikrotiklmepisowifi/refs/heads/main/userprofilescript.rsc"
:local loginFile   "gh-on-login.rsc"
:local logoutFile  "gh-on-logout.rsc"
:local ghHotspotBase     "https://raw.githubusercontent.com/lmepisowifi/mikrotiklmepisowifi/main/hotspot"
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


# ==========================================
# PART 3: SYNC HOTSPOT HTML
# ==========================================

:local localVersion ""
:local ghVersion    ""

# ---- Read local version.txt ----
:do {
    :local raw [/file get [find name=$localVersionFile] contents]
    :set localVersion [:pick $raw 0 ([:len $raw] - 1)]
    :if ($localVersion = "") do={ :set localVersion $raw }
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
        :local raw [/file get [find name="hs-gh-version.txt"] contents]
        :set ghVersion [:pick $raw 0 ([:len $raw] - 1)]
        :if ($ghVersion = "") do={ :set ghVersion $raw }
        :do { /file remove [find name="hs-gh-version.txt"] } on-error={}
        :set vDone true
    } on-error={
        :log warning ("HotspotSync: version.txt fetch failed, attempt " . $vAttempt . ", retrying in 30s...")
        :put ("version.txt retry " . $vAttempt . " in 30s...")
        :do { /file remove [find name="hs-gh-version.txt"] } on-error={}
        :delay 30s
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
    # PHASE 2: DELETE OLD HOTSPOT FOLDER
    # ==========================================

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
# Pass 2: delete leftover empty directories (skip hotspot/data and config.js parents)
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

    # ==========================================
    # PHASE 3: DOWNLOAD NEW HOTSPOT FROM GITHUB
    # ==========================================

    :local manifest  ""
    :local manifestOk false

    # Fetch manifest.txt (infinite retry)
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
            :log warning ("HotspotSync: manifest.txt fetch failed, attempt " . $mAttempt . ", retrying in 30s...")
            :put ("manifest.txt retry " . $mAttempt . " in 30s...")
            :do { /file remove [find name="hs-manifest.txt"] } on-error={}
            :delay 30s
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
                # Strip \r if Windows line endings
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

                    # Download with infinite retry
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
                            :log warning ("HotspotSync: Failed " . $line . " attempt " . $dlAttempt . ", retrying in 30s...")
                            :put ("Retry " . $dlAttempt . ": " . $line . " - waiting 30s")
                            :do { /file remove [find name=$dlDst] } on-error={}
                            :delay 30s
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
    # ==========================================
        # PHASE 4: RUN USERPROFILESCRIPT AFTER UPDATE
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
                :log info "HotspotSync: Running userprofilescript after HTML update..."
                /import file-name="hs-userprofile.rsc"
                :do { /file remove [find name="hs-userprofile.rsc"] } on-error={}
                :set upsDone true
                :put "userprofilescript: applied"
            } on-error={
                :log warning ("HotspotSync: userprofilescript fetch/run failed, attempt " . $upsAttempt . ", retrying in 30s...")
                :put ("userprofilescript retry " . $upsAttempt . " in 30s...")
                :do { /file remove [find name="hs-userprofile.rsc"] } on-error={}
                :delay 30s
            }
        }
}
