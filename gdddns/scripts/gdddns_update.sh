#!/bin/sh

eval `dbus export gdddns_`

source /koolshare/scripts/base.sh

if [ "$gdddns_enable" != "1" ]; then
    echo "not enable"
    exit
fi

urlencode() {
    # urlencode <string>
    out=""
    while read -n1 c; do
        case $c in
            [a-zA-Z0-9._-]) out="$out$c" ;;
            *) out="$out`printf '%%%02X' "'$c"`" ;;
        esac
    done
    echo -n $out
}

enc() {
    echo -n "$1" | urlencode
}

update_record() {
    curl -kLsX PUT "https://api.godaddy.com/v1/domains/$gdddns_domain/records/A/$(enc "$gdddns_name")" \
                -H "accept: application/json" \
                -H "Content-type: application/json" \
                -H "Authorization: sso-key $gdddns_key:$gdddns_secret" \
        -d "[{\"data\":\"$ip\",\"ttl\":$gdddns_ttl,\"port\":443,\"protocol\":\"https\",\"weight\":1}]"
}

record_response() {
        curl -kLsX GET -H "Authorization: sso-key $gdddns_key:$gdddns_secret" \
                -H "Content-type: application/json" "https://api.godaddy.com/v1/domains/$gdddns_domain/records/A/$(enc "$gdddns_name")"
}

die () {
    echo $1
    dbus ram gdddns_last_act="$now: failed($1)"
}

echo "start gdddns"

now=`date '+%Y-%m-%d %H:%M:%S'`
ip=`$gdddns_curl 2>&1` || die "$ip"

[ "$gdddns_curl" = "" ] && gdddns_curl="curl -s whatismyip.akamai.com"
[ "$gdddns_dns" = "" ] && gdddns_dns="114.114.114.114"
[ "$gdddns_ttl" = "" ] && gdddns_ttl="600"

echo "do gdddns"

if [ "$?" -eq "0" ]; then
    current_ip=`record_response | grep -oE '([0-9]{1,3}\.?){4}'|head -n 1`
    if [ "$ip" = "$current_ip" ]; then
        echo "skipping"
#                new_ip=`record_response | grep -oE '([0-9]{1,3}\.?){4}'|head -n 1`
        dbus set gdddns_last_act="$now: skipping,router IP:($ip),A record IP:($current_ip)"
    else
        echo "changing"
        update_record
                new_ip=`record_response | grep -oE '([0-9]{1,3}\.?){4}'|head -n 1`
           if [ "$new_ip" = "$ip" ]; then
            dbus set gdddns_last_act="$now: update success,router IP:($ip),A record IP:($new_ip)"
            else
            dbus set gdddns_last_act="$now: updata failed!pleace check"
           fi
    fi
fi