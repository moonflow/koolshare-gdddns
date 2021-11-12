#!/bin/sh

if [ "`dbus get gdddns_enable`" == "1" ]; then
    ps | grep 'gdddns_update' | grep -v grep | awk '{print $1}' | xargs kill -9
    /koolshare/scripts/gdddns_update.sh &
else
    ps | grep 'gdddns_update' | grep -v grep | awk '{print $1}' | xargs kill -9
fi
