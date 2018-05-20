#!/bin/sh

# i3status wrapper for displaying correct battery status on N900/bq27200
#
# Author:
# - Sicelo A. Mhlongo <absicsz@gmail.com> (2018)
#
# Based on i3status/contrib/net-speed.sh by
#
# - Moritz Warning <moritzwarning@web.de> (2016)
# - Zhong Jianxin <azuwis@gmail.com> (2014)
#
# See file LICENSE in the i3status root directory for license information.
#

battery_path="/sys/class/power_supply/bq27200-0/"

get_battery(){
        read capacity < "${battery_path}capacity"
        read chg_full < "${battery_path}charge_full"
        read voltage < "${battery_path}voltage_now"
        read disch_rate < "${battery_path}current_now"
        notification="$capacity%\/$(( ( chg_full / 1000 ) ))mAh -- $(( ( voltage / 1000 ) ))mV @ $(( ( disch_rate / -1000 ) ))mA"
}

# When 'output_mode' is set to "i3bar", i3status produces JSON output. We
# must read and emit the first three lines of output without modification
# as they make up the header. Once in the 'while' loop, we read a line of
# output from i3status, remove the opening field delimiter ,[ and prepend
# the calculated battery info and a delimiter

/usr/bin/i3status -c ~/.config/i3/i3status.conf |  ( read line && \
echo "$line" && read line && echo "$line" && read line && echo "$line" && \
while :
do
        read line
        get_battery
        echo ",[{\"full_text\":\"${notification}\"},${line#,\[}" || exit 1
done )
