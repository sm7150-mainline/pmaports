#!/bin/sh

# Current modem routing
#
#  1 - Digital PCM
#  0 - I2S master
#  0 - Primary mode (short sync)
#  2 - 512kHz clock (512kHz / 16bit = 32k samples/s)
#  0 - 16bit linear format
#  1 - 16k sample/s
#  1 - 1 slot
#  1 - map to first slot (the only slot)
#
QDAI_CONFIG="1,0,0,2,0,1,1,1"
QCFG_CONFIG="physical"

DEV=/dev/EG25.AT

# Read current config
QDAI_ACTUAL_CONFIG=$(echo "AT+QDAI?" | atinout - $DEV -)
QCFG_ACTUAL_CONFIG=$(echo 'AT+QCFG="risignaltype"' | atinout - $DEV -)

if echo $QDAI_ACTUAL_CONFIG | grep -q $QDAI_CONFIG && echo $QCFG_ACTUAL_CONFIG | grep -q $QCFG_CONFIG
then
	echo "Modem already configured"
	exit 0
fi

# Modem not configured, we need to send it the digital interface configuration,
# then reboot it

# Configure audio
RET=$(echo "AT+QDAI=$QDAI_CONFIG" | atinout - $DEV -)

if echo $RET | grep -q OK
then
	echo "Successfully configured modem audio"
else
	echo "Failed to set modem audio up: $RET"
	exit 1
fi

# Configure ring device
RET=$(echo 'AT+QCFG="risignaltype","$QCFG_CONFIG"' | atinout - $DEV -)

if echo $RET | grep -q OK
then
	echo "Successfully configured modem ring wakeup"
else
	echo "Failed to set modem ring wakeup: $RET"
fi

# Reset module
# 1 Set the mode to full functionality (vs 4: no RF, and 1: min functionality)
# 1 Reset the modem before changing mode (only available with 1 above)
#
RET=$(echo "AT+CFUN=1,1" | atinout - $DEV -)

if echo $RET | grep -q OK
then
	echo "Successfully reset the modem to apply audio configuration"
else
	echo "Failed to reset the modem to apply audio configuration: $RET"
fi
