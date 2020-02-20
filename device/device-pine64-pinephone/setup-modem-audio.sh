#!/bin/sh

RET=$(echo "AT+QDAI=1,0,0,2,0,1,1,1" | atinout - /dev/EG25.AT -)

if echo $RET | grep -q OK; then
	echo "Successfully configured modem audio"
else
	echo "Failed to set modem audio up: $RET"
	exit 1
fi
