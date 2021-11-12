#!/bin/sh

if [ "`dbus get gdddns_enable`" == "1" ]; then
    cru d mygodaddy
    cru a mygodaddy "*/1 * * * * /koolshare/scripts/gdddns_update.sh"
else
    cru d mygodaddy
fi
