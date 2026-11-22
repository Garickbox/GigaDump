#!/bin/sh
set -eu
PUB_DIR="/opt/zapret2/yadoma-pub"
OUT="$PUB_DIR/yadoma-rules.json"
TMP="$PUB_DIR/yadoma-rules.json.tmp"
mkdir -p "$PUB_DIR"
AWK_FP="/opt/zapret2/lists/rkn-false-positive.txt"
FILES=""
for f in \
  /opt/zapret2/extra_strats/TCP/YT/List.txt \
  /opt/zapret2/extra_strats/TCP/YT_GV/List.txt \
  /opt/zapret2/extra_strats/TCP/RKN/Discord.txt \
  /opt/zapret2/extra_strats/TCP_Discord.txt \
  /opt/zapret2/lists/custom.txt \
  /opt/zapret2/lists/extra-domains.txt \
  /opt/zapret2/extra_strats/TCP/RKN/List.txt \
  /opt/zapret2/lists/telegram_ips.txt \
  /opt/zapret2/lists/meta-ranges.txt; do
  [ -f "$f" ] && FILES="$FILES $f"
done
awk -v fp="$AWK_FP" '
BEGIN {
  split("gosuslugi.ru esia.gosuslugi.ru sberbank.ru online.sberbank.ru tbank.ru tinkoff.ru alfabank.ru vtb.ru online.vtb.ru raiffeisen.ru gazprombank.ru sovcombank.ru psbank.ru yandex.ru ya.ru yandex.net vk.com vk.ru max.ru oneme.ru ozon.ru wildberries.ru wb.ru mail.ru 2ip.ru dns-shop.ru avito.ru rambler.ru ok.ru kinopoisk.ru ivi.ru mos.ru nalog.ru cbr.ru pochta.ru rzd.ru mts.ru beeline.ru megafon.ru t2.ru tele2.ru lan local arpa localhost", ex, " ")
  for (i in ex) excl[ex[i]] = 1
  if (fp != "" && (getline line < fp) >= 0) {
    close(fp)
    while ((getline line < fp) > 0) {
      gsub(/\r/, "", line); sub(/#.*/, "", line); gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      if (line != "") excl[tolower(line)] = 1
    }
    close(fp)
  }
  split("youtube.com youtu.be ytimg.com yt.be ggpht.com googlevideo.com gvt1.com youtubei.googleapis.com telegram.org t.me tdesktop.com telegra.ph telesco.pe tg.dev fragment.com openai.com chatgpt.com oaistatic.com oaiusercontent.com oaistatsig.com sora.com claude.ai anthropic.com gemini.google.com aistudio.google.com instagram.com cdninstagram.com facebook.com fbcdn.net whatsapp.com whatsapp.net threads.net discord.com discord.gg discordapp.com discord.media x.com twitter.com twimg.com api.ipify.org ipinfo.io ifconfig.me", core, " ")
  for (i in core) { d = core[i]; if (!(d in ds_seen)) { ds_seen[d] = 1; ds[++nds] = d } }
}
{
  gsub(/\r/, "", $0)
  sub(/#.*/, "", $0)
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
  if ($0 == "") next
  s = tolower($0)
  sub(/^https?:\/\//, "", s)
  sub(/\/.*$/, "", s)
  sub(/^\*\./, "", s)
  sub(/^\.+/, "", s)
  sub(/:[0-9]+$/, "", s)
  if (s == "") next
  if (s ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(\/[0-9]+)?$/) {
    if (s !~ /\//) s = s "/32"
    if (!(s in ip_seen)) { ip_seen[s] = 1; ips[++nips] = s }
    next
  }
  if (s ~ /\./) {
    if (s ~ /^[a-z0-9.-]+$/ && !(s in excl)) {
      skip = 0
      for (e in excl) {
        if (length(s) > length(e) && substr(s, length(s) - length(e)) == "." e) { skip = 1; break }
      }
      if (!skip && !(s in ds_seen)) { ds_seen[s] = 1; ds[++nds] = s }
    }
    next
  }
  if (length(s) >= 5 && s ~ /^[a-z0-9-]+$/ && !(s in kw_seen)) {
    kw_seen[s] = 1; kw[++nkw] = s
  }
}
END {
  printf "{\"version\":2,\"rules\":[{\"domain_suffix\":["
  for (i = 1; i <= nds; i++) printf "%s\"%s\"", (i>1?",":""), ds[i]
  printf "]"
  if (nkw > 0) {
    printf ",\"domain_keyword\":["
    for (i = 1; i <= nkw; i++) printf "%s\"%s\"", (i>1?",":""), kw[i]
    printf "]"
  }
  if (nips > 0) {
    printf ",\"ip_cidr\":["
    for (i = 1; i <= nips; i++) printf "%s\"%s\"", (i>1?",":""), ips[i]
    printf "]"
  }
  printf "}]}\n"
}' $FILES > "$TMP"
mv -f "$TMP" "$OUT"
DOCROOT=$(sed -n 's/.*server\.document-root[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' /opt/zapret2/webpanel/lighttpd.conf 2>/dev/null | head -n1 || true)
[ -n "$DOCROOT" ] && [ -d "$DOCROOT" ] && cp -f "$OUT" "$DOCROOT/yadoma-rules.json" || true
